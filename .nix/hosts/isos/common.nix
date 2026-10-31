# What both ISOs share: nixpkgs' installer, with eyouga in place of its
# "nixos" user. installation-device.nix names "nixos" in a handful of places;
# each one is redirected here (graphical.nix handles the desktop ones).
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # The cross-platform module only: eyouga's shell, SSH key and CLI tools,
    # without the libvirtd/podman/syncthing a real host gets.
    ../../modules/configuration.nix
    ../../modules/cluster-tools.nix
    ../../modules/nixos/locale.nix
    ./tools.nix
  ];

  users.users.nixos.enable = false;

  users.users.eyouga = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
    # Empty, not unset: unset is a locked account, which KDE's lock screen
    # would never let back in. Nothing remote can use it (sshd is key-only).
    initialHashedPassword = "";
  };

  services.getty.autologinUser = lib.mkForce "eyouga";
  services.getty.helpLine = lib.mkForce ''
    Logged in as eyouga, with passwordless sudo. SSH accepts eyouga's key only.
    The dotfiles are stowed from ~/.dotfiles, a snapshot of the flake:
      sudo nixos-install --flake ~/.dotfiles/.nix#<host>

    To set up a wireless connection, run `nmtui`.
  '';
  nix.settings.trusted-users = [ "eyouga" ];

  # Key or nothing. PasswordAuthentication alone leaves keyboard-interactive
  # (another way to type a password, through PAM) to how PAM happens to be
  # wired; AuthenticationMethods makes sshd itself refuse anything else.
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    AuthenticationMethods = "publickey";
    AllowUsers = [ "eyouga" ];
    PermitRootLogin = lib.mkForce "no";
  };

  # A writable copy of the repo's tracked files (sourceInfo is the repo root,
  # not .nix/), stowed before eyouga is logged in on tty1 or in Plasma.
  systemd.services.eyouga-dotfiles = {
    description = "Copy and stow eyouga's dotfiles";
    wantedBy = [ "multi-user.target" ];
    before = [
      "getty@tty1.service"
      "display-manager.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [
      coreutils
      stow
      util-linux
    ];
    script = ''
      home=/home/eyouga
      [ -e $home/.dotfiles ] && exit 0
      cp -r ${inputs.self.sourceInfo.outPath} $home/.dotfiles
      chmod -R u+w $home/.dotfiles
      chown -R eyouga:users $home/.dotfiles
      runuser -u eyouga -- stow -d $home/.dotfiles -t $home .
    '';
  };

  # No kernelPackages here on purpose: the installer enables ZFS (needed for
  # disko on def-jam), and its default LTS kernel always has a matching ZFS.
  # modules/nixos/configuration.nix, with its linuxPackages_latest, stays out.
  nixpkgs.hostPlatform = "x86_64-linux";
}
