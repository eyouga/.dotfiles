{ config, pkgs, ... }:
{
  imports = [
    ./configuration.nix
    ../desktop.nix
  ];

  environment.systemPackages = with pkgs; [
    android-studio
    anki-bin
    beeper
    discord
    iina
    intellij-idea
    libreoffice-bin
    protonmail-desktop
    # maccy
    # obsidian
  ];
}
