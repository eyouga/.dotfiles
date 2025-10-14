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
    lutris
    keepassxc
    git-credential-manager
    protonvpn-gui
    ryubing
    nextcloud-client
    obsidian
    xenia-canary
    thunderbird
    inputs.zen-browser.packages."${system}".default
    inputs.fjordlauncher.packages."${pkgs.system}".fjordlauncher
  ];

  programs = {
    adb.enable = true;
    kdeconnect.enable = true;
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
