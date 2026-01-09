{ config, pkgs, ... }:
{
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };
  systemd = {
    packages = [ pkgs.waydroid-helper ];
    services.waydroid-mount.wantedBy = [ "multi-user.target" ];
  };
  programs = {
    adb.enable = true;
    kdeconnect.enable = true;
  };
  environment.systemPackages = with pkgs; [
    qtscrcpy
    waydroid-helper
  ];
  users.users.eyouga.extraGroups = [
    "adbusers"
  ];

}
