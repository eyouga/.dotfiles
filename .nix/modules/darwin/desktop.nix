{ config, pkgs, ... }:
{
  imports = [
    ./configuration.nix
    ../desktop.nix
  ];

  environment.systemPackages = with pkgs; [
    iina
    maccy
    obsidian
  ];
}
