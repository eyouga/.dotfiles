{
  inputs,
  config,
  lib,
  ...
}:

let
  inherit (lib)
    elemAt
    filter
    length
    listToAttrs
    nameValuePair
    splitString
    unique
    ;

  # The only place a tap is spelled out by hand.
  #
  # Key is the Homebrew tap name, i.e. the "owner/tap" you write inside a
  # fully-qualified package such as "magnuspladsen/tap/proton-ish".
  # The git repo nix-homebrew actually clones is "owner/homebrew-tap".
  #
  # Adding a tap = one flake input + one line here. Everything below is derived.
  tapSources = {
    "homebrew/core" = inputs.homebrew-core;
    "homebrew/cask" = inputs.homebrew-cask;
    "magnuspladsen/tap" = inputs.magnuspladsen-tap;
  };

  # Homebrew trusts these out of the box and rejects `brew trust` on them.
  # They also stay tapped unconditionally: dropping homebrew/core would make
  # nix-homebrew fall back to the Homebrew API instead of the pinned checkout.
  officialTaps = [
    "homebrew/core"
    "homebrew/cask"
  ];

  # The module system coerces bare strings into submodules, so every entry
  # of homebrew.{brews,casks} has a `.name`, whatever spelling was used.
  brewNames = map (b: b.name) config.homebrew.brews;
  caskNames = map (c: c.name) config.homebrew.casks;

  # "owner/tap/pkg" comes from a third-party tap; a bare "pkg" comes from core/cask.
  isQualified = name: length (splitString "/" name) == 3;
  tapOf =
    name:
    let
      p = splitString "/" name;
    in
    "${elemAt p 0}/${elemAt p 1}";

  qualifiedBrews = filter isQualified brewNames;
  qualifiedCasks = filter isQualified caskNames;

  # Exactly the taps the current package lists need — add a cask, the tap
  # appears; drop the last cask from a tap and the tap disappears with it.
  usedTaps = unique (officialTaps ++ map tapOf (qualifiedBrews ++ qualifiedCasks));

  unknownTaps = filter (t: !(tapSources ? ${t})) usedTaps;

  # "owner/tap" -> "owner/homebrew-tap", the key nix-homebrew.taps expects.
  repoKey =
    tap:
    let
      p = splitString "/" tap;
    in
    "${elemAt p 0}/homebrew-${elemAt p 1}";
in

{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  assertions = [
    {
      assertion = unknownTaps == [ ];
      message = ''
        These taps are referenced by homebrew.brews/casks but are not in
        `tapSources` in modules/darwin/brew.nix:
          ${lib.concatStringsSep "\n  " unknownTaps}
        For each one, add a flake input pointing at github:<owner>/homebrew-<tap>
        with `flake = false;`, then map it in `tapSources`.
      '';
    }
  ];

  nix-homebrew = {
    enable = true;
    autoMigrate = true;
    enableRosetta = false;
    user = "eyouga";
    taps = listToAttrs (map (t: nameValuePair (repoKey t) tapSources.${t}) usedTaps);
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
    taps = usedTaps;
    casks = [
      "activitywatch"
      "amethyst"
      "claude"
      "deezer"
      "eclipse-ide"
      "ente-auth"
      "gimp"
      "hermes-desktop"
      "highball"
      "karabiner-elements"
      "kdenlive"
      "keepassxc"
      "nextcloud"
      "magnuspladsen/tap/proton-ish"
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
