{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
{
  # modules/nixos/configuration.nix sets linuxPackages_latest for every host,
  # and ZFS lags it (2.4.4 doesn't build on 7.3). The LTS kernel always has a
  # matching ZFS, so a nixpkgs bump can't break the nightly autoUpgrade here.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
  boot.supportedFilesystems.zfs = true;
  # The 26.11 default; set explicitly to silence the evaluation warning. It
  # only governs pools imported in the initrd for /, and / is btrfs here.
  # fast and tank fall under forceImportAll, already false.
  boot.zfs.forceImportRoot = false;

  # Random, but fixed forever: ZFS refuses to auto-import a pool last used by
  # another hostid. Never reuse the old TrueNAS box's (825467552).
  networking.hostId = "6b24977d";

  # Imported in stage 2, after /persist (and so the key files) is mounted.
  boot.zfs.extraPools = [
    "fast"
    "tank"
  ];

  # disko gives every dataset a fileSystems entry, and zfs-mount's
  # `zfs mount -a` raced those mount units on the first boot ("dataset is
  # busy"). Let the units go first; zfs-mount then only picks up datasets
  # made by hand later.
  systemd.services.zfs-mount.after = map (fs: "${utils.escapeSystemdPath fs.mountPoint}.mount") (
    lib.filter (fs: fs.fsType == "zfs") (lib.attrValues config.fileSystems)
  );

  # Uncapped, the ARC takes up to half of the 64 G and gives it back slower
  # than kubelet's memory accounting expects: pods get OOM-killed.
  boot.kernelParams = [ "zfs.zfs_arc_max=${toString (20 * 1024 * 1024 * 1024)}" ];

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
    };
    trim.enable = true;
    # Pool events to ntfy.sh, straight from the host, so a failing disk is
    # reported even with the cluster down. ZED reports each vdev turning
    # FAULTED, DEGRADED, REMOVED or UNAVAIL, so a second IronWolf failing
    # still alerts while tank is already DEGRADED (hdd4 OFFLINE doesn't count).
    zed.settings = {
      # zed.rc is a shell file every zedlet sources, so the value can be a
      # command substitution: the topic stays out of this public repo and
      # the world-readable store.
      ZED_NTFY_TOPIC = "$(cat ${config.sops.secrets.ntfy-topic.path})";
      # Also a push when a healthy pool's scrub or resilver finishes: the
      # monthly scrub of fast proves this path still works.
      ZED_NOTIFY_VERBOSE = true;
    };
  };

  services.sanoid = {
    enable = true;
    templates = {
      # App state: small, changes often, cheap to keep many of.
      app = {
        hourly = 24;
        daily = 30;
        monthly = 6;
        autosnap = true;
        autoprune = true;
      };
      # Bulk files: daily is enough.
      bulk = {
        hourly = 0;
        daily = 30;
        monthly = 12;
        autosnap = true;
        autoprune = true;
      };
    };
    datasets = {
      "fast/k8s".useTemplate = [ "app" ];
      "fast/k8s-db".useTemplate = [ "app" ];
      "tank/nextcloud".useTemplate = [ "bulk" ];
      "tank/media" = {
        useTemplate = [ "bulk" ];
        recursive = true;
      };
      # tank/torrents: re-downloadable. tank/backup: syncoid's own snapshots.
    };
  };
}
