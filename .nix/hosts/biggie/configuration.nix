{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disko-config.nix
    ../../modules/user.nix
    ../../modules/packages.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/games.nix
    ../../modules/nixos/locale.nix
    ../../modules/nixos/packages.nix
    ../../modules/nixos/maintenance.nix
    ../../modules/nixos/configuration.nix
    ../../modules/wm/plasma.nix
  ];

  networking.hostName = "biggie";

  system.stateVersion = "25.05";

}
