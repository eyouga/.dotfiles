{
  config,
  nix-homebrew,
  homebrew-core,
  homebrew-cask,
  unmojang,
  ...
}:

{
  imports = [ nix-homebrew.darwinModules.nix-homebrew ];

  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = true;

    # User owning the Homebrew prefix
    user = "eyouga";

    # Optional: Declarative tap management
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
      "unmojang/homebrew-unmojang" = unmojang;
    };

    # Optional: Enable fully-declarative tap management
    #
    # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
    mutableTaps = true;
  };
  #homebrew packages
  homebrew = {
    enable = true;
    user = "eyouga";
    onActivation.autoUpdate = false;
    onActivation.upgrade = true;
    onActivation.cleanup = "zap"; # Uncomment this if you want all brew packages not defined in this file to be removed when updated
    brews = [
      {
        name = "syncthing";
        restart_service = true;
      }
    ];
    extraConfig = ''
      cask_args appdir: "~/Applications"
    '';
    taps = [
      "homebrew/cask"
      "homebrew/core"
      "unmojang/homebrew-unmojang"
    ];
    casks = [
      "discord"
      "zen"
      "zen@twilight"
      "wezterm@nightly"
      "keepassxc"
      "blender"
      "deezer"
      "obsidian"
      "libreoffice"
      "league-of-legends"
      "steam"
      "steamcmd"
      "utm"
      "visual-studio-code"
      "fjordlauncher"
      "kicad"
      "protonvpn"
      "qflipper"
      "kdenlive"
      "freecad"
      "localsend"
      "nextcloud"
      "osu"
      "sage"
    ];
    masApps = {
      #  "Ente Auth" = 6444121398;
      #  DaisyDisk = 411643860;
      #  Vimari = 1480933944;
      #  "WiFi Explorer" = 494803304;
      #  "Reeder 5." = 1529448980;
      #  "Okta Extension App" = 1439967473;
      Whatsapp = 310633997;
    };
  };
}
