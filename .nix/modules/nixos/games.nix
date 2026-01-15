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
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
    protontricks.enable = true;
    extest.enable = true;
  };

  environment.systemPackages = with pkgs; [
    mangohud
    limo
    winetricks
    ryubing
    xenia-canary
    lutris
    nexusmods-app-unfree
    prismlauncher
    protonup-qt
    hydralauncher
  ];
}
