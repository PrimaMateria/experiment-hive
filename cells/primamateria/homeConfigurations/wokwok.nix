#
# █▄█ ▄▀▄ █▄ ▄█ ██▀
# █ █ ▀▄▀ █ ▀ █ █▄▄ wokwok
#
{
  inputs,
  cell,
}: let
  inherit (cell) bees cli secrets;
in {
  bee = bees.wsl;
  imports = [
    cli.hive
    cli.shell
    cli.vcs
    cli.tmux
    cli.feeds
    cli.ambients
    cli.vifm
    cli.dev
    # cli.weechat

    {
      home = {
        username = "primamateria";
        homeDirectory = "/home/primamateria";
        stateVersion = "22.05";
      };

      primamateria.cli.dev = {
        projects = [
          {
            name = "nixos-hive";
            url = "git@github.com:PrimaMateria/nixos-hive.git";
          }
          {
            name = "startpages";
            url = "git@github.com:PrimaMateria/startpages.git";
          }
          {
            name = "blog";
            url = "git@github.com:PrimaMateria/blog.git";
          }
          {
            name = "nixos";
            url = "git@github.com:PrimaMateria/nixos.git";
          }
          {
            name = "neovim-nix";
            url = "git@github.com:PrimaMateria/neovim-nix.git";
          }
          {
            name = "finapi-build-library";
            url = "git@bitbucket.org:teaminvest/build-library.git";
          }
          {
            name = "finapi-cms";
            url = "git@bitbucket.org:teaminvest/cms.git";
          }
          {
            name = "finapi-design-system";
            url = "git@bitbucket.org:teaminvest/design-system.git";
          }
          {
            name = "finapi-hostpages";
            url = "git@bitbucket.org:teaminvest/hostpages.git";
          }
          {
            name = "finapi-process-ctrl";
            url = "git@bitbucket.org:teaminvest/process-ctrl.git";
          }
          {
            name = "finapi-widget-library";
            url = "git@bitbucket.org:teaminvest/widget-library.git";
          }
          {
            name = "finapi-js-loader";
            url = "git@bitbucket.org:teaminvest/js-loader.git";
          }
          {
            name = "finapi-js-static-resources";
            url = "git@bitbucket.org:teaminvest/js-static-resources.git";
          }
          {
            name = "web-form";
            url = "git@bitbucket.org:teaminvest/web-form.git";
          }
          {
            name = "web-form-loader";
            url = "git@bitbucket.org:teaminvest/web-form-loader.git";
          }
        ];
      };

      primamateria.cli.tmux = {
        sessions = [
          {
            name = "space";
            type = "prefabs";
            windows = [
              "nixos-hive"
              "neovim-nix"
              "dev-toolkit-nix"
              "startpages"
            ];
          }
          {
            name = "wokwok";
            type = "custom";
            windows = ''
              - window_name: reporting
                layout: even-horizontal
                start_directory: ~/reporting
                panes:
                  - nix develop --command ./current2
                  - nix develop
              - window_name: todo
                start_directory: ~/Documents
              - window_name: x
            '';
          }
          {
            name = "fds";
            type = "project";
            dir = "~/dev/finapi-design-system";
          }
          {
            name = "fwl";
            type = "project";
            dir = "~/dev/finapi-widget-library";
          }
          {
            name = "wf";
            type = "custom";
            windows = ''
              - window_name: feature
                start_directory: ~/dev/web-form/frontend
              - window_name: feature run
                start_directory: ~/dev/web-form/frontend
              - window_name: workbench
                start_directory: ~/dev/web-form/frontend
              - window_name: develop
                start_directory: ~/dev/wf-develop/frontend
              - window_name: develop run
                start_directory: ~/dev/wf-develop/frontend
            '';
          }
          {
            name = "cd";
            type = "project";
            dir = "~/dev/finapi-customer-dashboard-ui";
          }
          {
            name = "fjsl";
            type = "project";
            dir = "~/dev/finapi-js-loader";
          }
          {
            name = "wfl";
            type = "project";
            dir = "~/dev/web-form-loader";
          }
          {
            name = "fhp";
            type = "project";
            dir = "~/dev/finapi-hostpages";
          }
        ];
      };

      # TODO: move JIRA token to reporting flake
      programs.bash.initExtra = ''
        export JIRA_API_TOKEN=${secrets.wokwok.jiraApiToken}
      '';
    }
  ];
}
