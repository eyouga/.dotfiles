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
      "r"
    ];
    extraConfig = ''
      cask_args appdir: "~/Applications/Brew"
    '';
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = [
      "activitywatch"
      "android-studio"
      "anki"
      "deezer"
      "discord"
      "ente-auth"
      "geogebra"
      "gimp"
      "karabiner-elements"
      "keepassxc"
      "libreoffice"
      "nextcloud"
      "proton-mail"
      "protonvpn"
      "rstudio"
      "steam"
      "steamcmd"
    ];
    masApps = {
      "Canal+" = 694580816;
      Whatsapp = 310633997;
    };
  };
}
