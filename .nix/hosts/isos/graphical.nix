# nixpkgs' "combined" layout (installation-cd-graphical-combined.nix): a
# hidden parent holds what every boot entry shares, and each specialisation
# is one entry in the boot menu. GRUB sorts them by name, so "plasma" is the
# default and "tty" comes second.
{
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-base.nix")
    ./common.nix
  ];

  networking.hostName = "liveiso";

  # mkDefault: every specialisation inherits this and sets its own true.
  isoImage.showConfiguration = lib.mkDefault false;
  # Plain, so it beats the plasma6 module's mkDefault: iso-image.nix asserts
  # every specialisation has the same volumeID, which embeds the edition.
  isoImage.edition = "graphical";

  specialisation.plasma.configuration = {
    imports = [
      (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
      ../../modules/wm/plasma.nix
    ];

    isoImage.showConfiguration = true;
    isoImage.configurationName = "Plasma";

    services.displayManager.autoLogin.user = lib.mkForce "eyouga";

    environment.systemPackages = with pkgs; [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta
      keepassxc
      localsend
    ];
    # installation-cd-graphical-base.nix's list (and rsync from -base),
    # minus Firefox: zen-browser takes its place.
    environment.defaultPackages = lib.mkForce (
      with pkgs;
      [
        gparted
        mesa-demos
        nano
        rsync
        vim
      ]
    );

    # The account has no password, and an idle install shouldn't sit behind
    # a lock screen anyway.
    environment.etc."xdg/kscreenlockerrc".text = ''
      [Daemon]
      Autolock=false
    '';

    # Upstream's version of this rule hardcodes /home/nixos; same links, moved.
    systemd.tmpfiles.settings."10-installer-desktop" = lib.mkForce {
      "/home/eyouga/Desktop".d = {
        user = "eyouga";
        group = "users";
        mode = "0755";
      };
      "/home/eyouga/Desktop/nixos-manual.desktop"."L+".argument =
        "/run/current-system/sw/share/applications/nixos-manual.desktop";
      "/home/eyouga/Desktop/gparted.desktop"."L+".argument =
        "${pkgs.gparted}/share/applications/gparted.desktop";
      "/home/eyouga/Desktop/calamares.desktop"."L+".argument =
        "${pkgs.calamares-nixos}/share/applications/calamares.desktop";
    };
  };

  specialisation.tty.configuration = {
    isoImage.showConfiguration = true;
    isoImage.configurationName = "Console";
  };
}
