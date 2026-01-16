{
  inputs,
  config,
  ...
}:

{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "eyouga";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
  };
  homebrew = {
    enable = true;
    user = "eyouga";
    onActivation.autoUpdate = false;
    onActivation.upgrade = true;
    onActivation.cleanup = "zap";
    brews = [
      {
        name = "syncthing";
        restart_service = true;
      }
      "mas"
    ];
    extraConfig = ''
      cask_args appdir: "~/Applications"
    '';
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = [
      "deezer"
      "discord"
      "gimp"
      "iina"
      "karabiner-elements"
      "keepassxc"
      "libreoffice"
      "nextcloud"
      "obsidian"
      "proton-mail"
      "protonvpn"
      "steam"
      "steamcmd"
    ];
    masApps = {
      Whatsapp = 310633997;
    };
  };
}
