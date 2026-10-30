{ config, pkgs, ... }:
{
  imports = [
    ./configuration.nix
    ../desktop.nix
  ];

  environment.systemPackages = with pkgs; [
    anki
    beeper
    deezer-desktop
    dnsmasq # For virtualisation
    hunspell
    hunspellDicts.en_US
    hunspellDicts.fr-moderne
    keepassxc
    libreoffice-qt6-fresh
    nextcloud-client
    obsidian
    proton-vpn
    thunderbird
    vesktop
  ];

  programs = {
    coolercontrol.enable = true;
    kdeconnect.enable = true;
    ssh.startAgent = true;
    virt-manager.enable = true;
  };

  services.syncthing = {
    enable = true;
    group = "users";
    user = "eyouga";
    dataDir = "/home/eyouga/sync";
    configDir = "/home/eyouga/.config/syncthing";
  };

  services.printing.enable = true;

  services.flatpak.enable = true;
}
