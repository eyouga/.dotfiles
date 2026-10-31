{ lib, pkgs, ... }:
{
  # modules/nixos/configuration.nix sets linuxPackages_latest for every host,
  # and ZFS lags it (2.4.4 doesn't build on 7.3). The LTS kernel always has a
  # matching ZFS, so a nixpkgs bump can't break the nightly autoUpgrade here.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
  boot.supportedFilesystems.zfs = true;

  # Random, but fixed forever: ZFS refuses to auto-import a pool last used by
  # another hostid. Never reuse the old TrueNAS box's (825467552).
  networking.hostId = "6b24977d";

  # Imported in stage 2, after /persist (and so the key files) is mounted.
  boot.zfs.extraPools = [
    "fast"
    "tank"
  ];

  # Uncapped, the ARC takes up to half of the 64 G and gives it back slower
  # than kubelet's memory accounting expects: pods get OOM-killed.
  boot.kernelParams = [ "zfs.zfs_arc_max=${toString (20 * 1024 * 1024 * 1024)}" ];

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
    };
    trim.enable = true;
    # Phase 4: ZED_NTFY_TOPIC goes here once the topic has a home outside git
    # (this repo is public); ZED ships the ntfy notifier itself.
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
