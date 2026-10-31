{
  inputs,
  lib,
  pkgs,
  ...
}:
# Erase-your-darlings on the disko LUKS + btrfs layout: every boot starts from
# an empty `root` subvolume, and only what /persist lists survives. Assumes
# the LUKS device is named "crypted" (both hosts' disko configs) and a
# `persist` subvolume. A separate `home` subvolume, if a host has one, is not
# touched.
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # The initrd is always systemd now, so the rollback is a stage-1 unit that
  # runs between unlocking LUKS and mounting /.
  boot.initrd.systemd = {
    initrdBin = [
      pkgs.btrfs-progs
      pkgs.findutils
    ];
    services.rollback-root = {
      description = "Move the old root subvolume aside and start from an empty one";
      wantedBy = [ "initrd.target" ];
      requires = [ "systemd-cryptsetup@crypted.service" ];
      after = [ "systemd-cryptsetup@crypted.service" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /btrfs
        mount -t btrfs -o subvol=/ /dev/mapper/crypted /btrfs

        # Keep the old root for 30 days, so a path you forgot to persist can
        # still be fished out of /btrfs/old_roots/<boot time>/.
        if [ -e /btrfs/root ]; then
          mkdir -p /btrfs/old_roots
          mv /btrfs/root "/btrfs/old_roots/$(date -r /btrfs/root +%Y-%m-%d_%H%M%S)"
        fi

        # systemd creates nested subvolumes (/var/lib/machines, portables), and
        # `btrfs subvolume delete` refuses a subvolume that still has children.
        delete_recursively() {
          btrfs subvolume list -o "$1" | cut -f 9- -d ' ' | while read -r sub; do
            delete_recursively "/btrfs/$sub"
          done
          btrfs subvolume delete "$1"
        }
        find /btrfs/old_roots -mindepth 1 -maxdepth 1 -mtime +30 | while read -r old; do
          delete_recursively "$old"
        done

        btrfs subvolume create /btrfs/root
        umount /btrfs
      '';
    };
  };

  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos" # uid/gid allocations; without it, ids can shift between boots
      "/var/lib/systemd" # timer stamps, random seed, coredumps
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  # /etc/shadow is wiped with the rest of /, so `passwd` can't stick. The hash
  # lives in /persist instead: `mkpasswd -m yescrypt > /persist/passwords/eyouga`
  # at install time. Missing file = no password, but SSH keys still work.
  users.mutableUsers = false;
  users.users.eyouga.hashedPasswordFile = "/persist/passwords/eyouga";
}
