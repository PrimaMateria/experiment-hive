{
  inputs,
  cell,
}: let
  inherit (cell) secrets;
  inherit (inputs) nixpkgs;

  synapseLoggingConfiguration = nixpkgs.writeTextFile {
    name = "primamateria.ddns.net.log.config";
    text = builtins.toJSON {
      version = 1;
      formatters.precise.format = "%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(request)s - %(message)s";
      handlers = {
        file = {
          class = "logging.handlers.TimedRotatingFileHandler";
          formatter = "precise";
          filename = "/var/log/synapse/synapse.log";
          when = "midnight";
          backupCount = 3;
          encoding = "utf8";
        };
        buffer = {
          class = "synapse.logging.handlers.PeriodicallyFlushingMemoryHandler";
          target = "file";
          capacity = 10;
          flushLevel = 30;
          period = 5;
        };
        console = {
          class = "logging.StreamHandler";
          formatter = "precise";
        };
      };
      loggers = {
        "synapse.storage.sql".level = "INFO";
      };
      root = {
        level = "INFO";
        handlers = ["buffer"];
      };
      disable_existing_loggers = false;
    };
  };

  synapseConfiguration = nixpkgs.writeTextFile {
    name = "synapse-config.yaml";
    text = builtins.toJSON {
      server_name = "primamateria.ddns.net";
      pid_file = "/data/homeserver.pid";
      listeners = [
        {
          port = 8008;
          tls = false;
          type = "http";
          x_forwarded = true;
          resources = [
            {
              names = ["client" "federation"];
              compress = false;
            }
          ];
        }
      ];

      database = {
        name = "psycopg2";
        args = {
          user = "synapse";
          password = "synapse";
          dbname = "synapse";
          host = "synapse-db";
        };
      };

      report_stats = true;
      log_config = "/primamateria.ddns.net.log.config";
      media_store_path = "/data/media_store";

      # Forbid public registration
      enable_registration = false;
      registration_shared_secret = secrets.matrix.synapse.registration_shared_secret;

      macaroon_secret_key = secrets.matrix.synapse.macaroon_secret_key;
      form_secret = secrets.matrix.synapse.form_secret;

      # Signing key is autogenerated
      signing_key_path = "/data/primamateria.ddns.net.signing.key";
      trusted_key_servers = [
        {server_name = "matrix.org";}
      ];
    };
  };

  elementConfiguration = nixpkgs.writeTextFile {
    name = "element-config.json";
    text = builtins.toJSON {
      # TODO
      default_server_config = {
        "m.homeserver" = {
          base_url = "https://primamateria.ddns.net";
          server_name = "primamateria.ddns.net";
        };
        "m.identity_server" = {
          base_url = "https://vector.im";
        };
      };
      brand = "Element";
      integrations_ui_url = "https://scalar.vector.im/";
      integrations_rest_url = "https://scalar.vector.im/api";
      integrations_widgets_urls = [
        "https://scalar.vector.im/_matrix/integrations/v1"
        "https://scalar.vector.im/api"
        "https://scalar-staging.vector.im/_matrix/integrations/v1"
        "https://scalar-staging.vector.im/api"
        "https://scalar-staging.riot.im/scalar/api"
      ];
      hosting_signup_link = "https://element.io/matrix-services?utm_source=element-web&utm_medium=web";

      uisi_autorageshake_app = "element-auto-uisi";
      showLabsSettings = true;
      piwik = {
        url = "https://piwik.riot.im/";
        siteId = 1;
        policyUrl = "https://element.io/cookie-policy";
      };
      roomDirectory = {
        servers = [
          "matrix.org"
          "gitter.im"
          "libera.chat"
        ];
      };
      enable_presence_by_hs_url = {
        "https://matrix.org" = false;
        "https://matrix-client.matrix.org" = false;
      };
      terms_and_conditions_links = [
        {
          url = "https://element.io/privacy";
          text = "Privacy Policy";
        }
        {
          url = "https://element.io/cookie-policy";
          text = "Cookie Policy";
        }
      ];
      hostSignup = {
        brand = "Element Home";
        cookiePolicyUrl = "https://element.io/cookie-policy";
        domains = [
          "matrix.org"
        ];
        privacyPolicyUrl = "https://element.io/privacy";
        termsOfServiceUrl = "https://element.io/terms-of-service";
        url = "https://ems.element.io/element-home/in-app-loader";
      };
      sentry = {
        dsn = "https://029a0eb289f942508ae0fb17935bd8c5@sentry.matrix.org/6";
        environment = "develop";
      };
      posthog = {
        projectApiKey = "phc_Jzsm6DTm6V2705zeU5dcNvQDlonOR68XvX2sh1sEOHO";
        apiHost = "https://posthog.hss.element.io";
      };
      features = {};
      map_style_url = "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx";
    };
  };

  dockerCompose = nixpkgs.writeTextFile {
    name = "matrix-docker-compose.yaml";
    text = builtins.toJSON {
      volumes = {
        synapse-data = null;
        synapse-db-data = null;
        synapse-log = null;
      };

      services = {
        synapse = {
          image = "matrixdotorg/synapse:latest";
          container_name = "synapse";
          restart = "unless-stopped";
          volumes = [
            "synapse-data:/data"
            "synapse-log:/var/log/synapse"
            "${synapseConfiguration}:/etc/synapse/synapse.yaml:ro"
            "${synapseLoggingConfiguration}:/primamateria.ddns.net.log.config:ro"
          ];
          environment = [
            "SYNAPSE_CONFIG_PATH=/etc/synapse/synapse.yaml"
          ];
          depends_on = [
            "synapse-db"
          ];
          labels = [
            "traefik.enable=true"

            # http is just redirected to https
            "traefik.http.middlewares.https_redirect.redirectscheme.scheme=https"
            "traefik.http.middlewares.https_redirect.redirectscheme.permanent=true"
            "traefik.http.routers.http-synapse.entrypoints=http"
            "traefik.http.routers.http-synapse.rule=PathPrefix(`/_matrix`) || PathPrefix(`/_synapse/client`)"
            "traefik.http.routers.http-synapse.middlewares=https_redirect"

            # https will pass all https request to subpath of /_matrix and /_synapse/client to synapse service to port 8008 as http
            "traefik.http.routers.https-synapse.entrypoints=https"
            "traefik.http.routers.https-synapse.rule=PathPrefix(`/_matrix`) || PathPrefix(`/_synapse/client`)"
            "traefik.http.routers.https-synapse.tls=true"
            "traefik.http.routers.https-synapse.tls.certresolver=http"
            "traefik.http.routers.https-synapse.service=synapse"
            "traefik.http.services.synapse.loadbalancer.server.port=8008"
          ];
        };

        synapse-db = {
          image = "postgres:alpine";
          container_name = "synapse-db";
          restart = "unless-stopped";
          environment = [
            # TODO
            "POSTGRES_USER=synapse"
            "POSTGRES_PASSWORD=synapse"
            "POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C"
          ];
          volumes = [
            "synapse-db-data:/var/lib/postgresql/data"
          ];
          labels = [
            "traefik.enable=false"
          ];
        };

        element = {
          image = "vectorim/element-web:latest";
          container_name = "element";
          restart = "unless-stopped";
          volumes = [
            "${elementConfiguration}:/app/config.json:ro"
          ];
          environment = [
            "BASE_URL=/element"
            "PUBLIC_URL=/element"
          ];
          labels = [
            "traefik.enable=true"

            # http is just redirected to https
            "traefik.http.middlewares.https_redirect.redirectscheme.scheme=https"
            "traefik.http.middlewares.https_redirect.redirectscheme.permanent=true"
            "traefik.http.routers.http-element.entrypoints=http"
            # "traefik.http.routers.http-element.rule=PathPrefix(`/element`)"
            "traefik.http.routers.http-element.rule=Host(`element.primamateria.ddns.net`)"
            "traefik.http.routers.http-element.middlewares=https_redirect"

            # https will pass all https request to subpath of /element  to
            # element service to port 80 as http and strip the prefix
            "traefik.http.middlewares.element_stripprefix.stripprefix.prefixes=element"
            "traefik.http.routers.https-element.entrypoints=https"
            # "traefik.http.routers.https-element.rule=PathPrefix(`/element`)"
            "traefik.http.routers.https-element.rule=Host(`element.primamateria.ddns.net`)"
            "traefik.http.routers.https-element.middlewares=element_stripprefix"
            "traefik.http.routers.https-element.tls=true"
            "traefik.http.routers.https-element.tls.certresolver=http"
            "traefik.http.routers.https-element.service=element"
            "traefik.http.services.element.loadbalancer.server.port=80"
          ];
        };
      };
    };
  };
in {
  home.packages = [
    (nixpkgs.writeShellApplication
      {
        name = "run-matrix";
        text = ''
          echo "Composing matrix"
          docker compose -p matrix --file ${dockerCompose} up -d
        '';
      })
  ];
}
