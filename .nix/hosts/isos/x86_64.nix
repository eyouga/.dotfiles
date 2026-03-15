{ pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ../../modules/nixos/desktop.nix
    ../../modules/wm/plasma.nix
  ];

  networking.hostName = "liveiso";
  nixpkgs.hostPlatform = "x86_64-linux";
}
