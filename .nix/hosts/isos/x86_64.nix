{ pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ../../modules/user.nix
    ../../modules/packages.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/packages.nix
    ../../modules/nixos/configuration.nix
    ../../modules/wm/plasma.nix
  ];

  networking.hostName = "liveiso";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
