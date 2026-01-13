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
    kdeconnect.enable = true;
  };
  environment.systemPackages = with pkgs; [
    scrcpy
    waydroid-helper
    android-tools
  ];
  users.users.eyouga.extraGroups = [
    "adbusers"
  ];

}
