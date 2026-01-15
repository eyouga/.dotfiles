{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../modules/packages.nix
    ../modules/darwin/defaults.nix
    ../modules/darwin/brew.nix
    ../modules/darwin/network.nix
    ../modules/darwin/packages.nix
  ];

  networking.hostName = "eminem";
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.defaults.NSGlobalDomain._HIHideMenuBar = lib.mkForce false;

  system.stateVersion = 6;
}
