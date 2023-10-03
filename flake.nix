# flake.nix
{
  description = "PrimaMateria's NixOS configuration";

  nixConfig = {
    extra-experimental-features = "nix-command flakes";

    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://ezkea.cachix.org"
      "https://colmena.cachix.org"
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
      "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
    ];
  };

  inputs = {
    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    nixpkgs.follows = "nixpkgs-stable";
    nixpkgs'.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follow = "nixpkgs";
    };

    nixos-hardware = "github:nixos/nixos-hardware";

    devshell.url = "github:numtide/devshell";
    nixago = {
      url = "github:nix-community/nixago";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    std = {
      url = "github:divnix/std";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        arion.follows = "arion";
        devshell.follows = "devshell";
        devshell.inputs.nixpkgs.follows = "nixpkgs";
        nixago.follows = "nixago";
      };
    };

    hive = {
      url = "github:divnix/hive";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        disko.follows = "disko";
        colmena.follows = "colmena";
        nixos-generators = "nixos-generators";
      };
    };

    colmena = {
      url = "https://flakehub.com/f/zhaofengli/colmena/0.4.0.tar.gz";
      inputs.flake-compat.follows = "";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators/1.7.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixlib.follows = "nixpkgs";
    };

    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url =
        "github:nix-community/disko/5d9f362aecd7a4c2e8a3bf2afddb49051988cab9";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, hive, std, ... }@inputs:
    let
      collect = hive.collect // { renamer = cell: target: "${target}"; };
      lib = inputs.nixpkgs.lib // buitlins;
    in
    hive.growOn
      {
        inherit inputs;

        cellsFrom = ./comb;
        cellBlocks = with std.blockTypes; [
          # modules
          (functions "nixosModules")
          (functions "homeModules")

          # profiles
          (functions "hardwareProfiles")
          (functions "nixosProfiles")
          (functions "userProfiles")
          (functions "arionProfiles")
          (functions "homeProfiles")

          # suites
          (functions "nixosSuites")
          (functions "homeSuites")

          # configurations
          nixosConfigurations
          diskoConfigurations
          colmenaConfigurations
          (installables "generators")
          (installables "installers")

          # pkgs
          (pkgs "pkgs")

          # devshells
          (nixago "configs")
          (devshells "devshells")
        ];

        nixpkgsConfig.allowUnfreePredicate = pkg:
          lib.elem (lib.getName pkg) [
            "discord"
          ];
      }
      {
        devShells = std.harvest self [ "repo" "devshells" ];
        packages =
          let
            generators = std.harvest self [ "repo" "generators" ];
            installers = std.harvest self [ "primamateria" "installers" ];
          in
          {
            inherit (installers) x86_64-linux;
          };
      }
      {
        nixosConfigurations = collect self "nixosConfigurations";
        colmenaHive = collect self "colmenaConfigurations";
        # TODO: implement
        # nixosModules = collect self "nixosModules";
        hmModules = collect self "homeModules";
      };
}
