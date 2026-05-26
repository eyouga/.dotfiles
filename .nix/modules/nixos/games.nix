{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  nixpkgs.overlays = [ inputs.millennium.overlays.default ];

  services.sunshine = {
    enable = false;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  programs.steam = {
    enable = true;
    package = pkgs.millennium-steam;
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
    #    lutris
    rpcs3
    #  nexusmods-app-unfree
    prismlauncher
    protonup-qt
    hydralauncher
  ];
}
