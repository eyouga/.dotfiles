{
  inputs,
  pkgs,
  ...
}:
{

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vesktop
    libreoffice-qt6-fresh
    hunspell
    hunspellDicts.fr-moderne
    hunspellDicts.en_US
    wezterm
    podman-compose
    keepassxc
    git-credential-manager
    protonvpn-gui
    nextcloud-client
    deezer-enhanced
    obsidian
    thunderbird
  ];

  programs.coolercontrol.enable = true;
  services.lact.enable = true;

  programs = {
    ssh.startAgent = true;
    zsh.enable = true;
  };

  services.syncthing = {
    enable = true;
    group = "users";
    user = "eyouga";
    dataDir = "/home/eyouga/sync";
    configDir = "/home/eyouga/.config/syncthing";
  };
}
