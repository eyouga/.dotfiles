{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  services.sunshine = {
    enable = false;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };
  programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };
}
