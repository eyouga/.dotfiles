{
  inputs,
  config,
  ...
}:

{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  nix-homebrew = {
    enable = true;
    autoMigrate = true;
    enableRosetta = false;
    user = "eyouga";
    taps = {
      "deskflow/homebrew-tap" = inputs.deskflow-tap;
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
      "amethyst"
      "android-studio"
      "anki"
      "beeper"
      "claude"
      "deezer"
      "deskflow"
      "discord"
      "eclipse-ide"
      "ente-auth"
      "geogebra"
      "gimp"
      "intellij-idea"
      "karabiner-elements"
      "kdenlive"
      "keepassxc"
      "libreoffice"
      "nextcloud"
      "proton-mail"
      "protonvpn"
      "rstudio"
      "steam"
      "steamcmd"
      "vorssaint"
    ];
    masApps = {
      "Canal+" = 694580816;
      Whatsapp = 310633997;
    };
  };
}
