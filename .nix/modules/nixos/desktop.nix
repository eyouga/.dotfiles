{ config, pkgs, ... }:
{
  imports = [
    ./configuration.nix
    ../desktop.nix
  ];

  environment.systemPackages = with pkgs; [
    anki
    deezer-enhanced
    dnsmasq # For virtualisation
    hunspell
    hunspellDicts.en_US
    hunspellDicts.fr-moderne
    keepassxc
    libreoffice-qt6-fresh
    nextcloud-client
    obsidian
    protonvpn-gui
    thunderbird
    vesktop
  ];

  programs.coolercontrol.enable = true;
  services.lact.enable = true;

  programs = {
    ssh.startAgent = true;
  };

  programs = {
    kdeconnect.enable = true;
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

  programs.virt-manager.enable = true;
}
