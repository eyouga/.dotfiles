{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.niri.enable = true;
  programs.waybar.enable = true; # top bar
  security.polkit.enable = true; # polkit
  services.gnome.gnome-keyring.enable = true; # secret service
  security.pam.services.swaylock = { };
  environment.systemPackages = with pkgs; [
    alacritty
    fuzzel
    swaylock
    mako
    swayidle
    wayland-utils # Wayland utilities
    wl-clipboard # Command-line copy/paste utilities for Wayland
  ];
}
