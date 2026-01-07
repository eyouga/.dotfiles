{ config, pkgs, ... }:
{
  virtualisation.waydroid.enable = true;
  programs = {
    adb.enable = true;
    kdeconnect.enable = true;
  };
  environment.systemPackages = with pkgs; [
    qtscrcpy
  ];
}
