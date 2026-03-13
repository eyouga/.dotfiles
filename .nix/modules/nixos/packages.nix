{
  inputs,
  pkgs,
  ...
}:
{
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
    podman-compose
    protonvpn-gui
    thunderbird
    vesktop
    wezterm
  ];

  programs.coolercontrol.enable = true;
  services.lact.enable = true;

  programs = {
    ssh.startAgent = true;
    zsh.enable = true;
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
}
