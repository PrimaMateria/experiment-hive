{
  inputs,
  cell,
}: let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
  inherit (cell) bees cli raspberrypi;
in {
  bee = bees.rpi;
  imports = [
    cli.pureNix
    cli.hive
    cli.shellMin
    raspberrypi.configurer

    {
      home = {
        username = "primamateria";
        homeDirectory = "/home/primamateria";
        stateVersion = "22.05";
      };
    }
  ];
}
