{
  config,
  pkgs,
  lib,
  home-manager,
  nur,
  ...
}:
{
  imports = [
    ../modules/packages.nix
    ../modules/darwin/m1.nix
    ../modules/darwin/defaults.nix
    ../modules/darwin/brew.nix
    ../modules/darwin/network.nix
    #    ../modules/wm/yabai.nix
  ];

  networking.hostName = "eminem";

  system.defaults.NSGlobalDomain._HIHideMenuBar = lib.mkForce false;

  system.stateVersion = 6;
}
