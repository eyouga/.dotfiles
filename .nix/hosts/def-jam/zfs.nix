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

  # A named snapshot before each app upgrade (fast/k8s@pre-<app>-<version>),
  # taken from the Mac without sudo. Only `snapshot` (ZFS also demands
  # `mount` with it; an unprivileged user can't mount on Linux anyway):
  # rollback and destroy stay root's. The grant is stored in the pool, so
  # this only re-asserts it at every boot.
  systemd.services.zfs-allow-snapshots = {
    description = "Delegate snapshots of the app datasets to eyouga";
    wantedBy = [ "multi-user.target" ];
    after = [ "zfs-import.target" ];
    wants = [ "zfs-import.target" ];
    path = [ config.boot.zfs.package ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      zfs allow -u eyouga snapshot,mount fast/k8s
      zfs allow -u eyouga snapshot,mount fast/k8s-db
    '';
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
      # Torrents + media (hardlinked, one dataset): two weeks to undo a
      # mistake. Short on purpose: a deleted torrent's space only frees once
      # the last snapshot holding it expires. Mostly re-downloadable; the
      # real second copy is the offsite one.
      data = {
        hourly = 0;
        daily = 14;
        monthly = 0;
        autosnap = true;
        autoprune = true;
      };
      # Replicas: snapshots arrive by syncoid. A longer tail than the source's,
      # since this is what's left if `fast` dies.
      replica = {
        hourly = 0;
        daily = 30;
        monthly = 12;
        autosnap = false;
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
      "tank/data".useTemplate = [ "data" ];
      # The replicas of fast/*: sanoid never snapshots them, it only ages out
      # what syncoid brings over.
      "tank/backup/fast" = {
        useTemplate = [ "replica" ];
        recursive = true;
        processChildrenOnly = true;
      };
      # The rsync copy of /persist (below) changes once a night.
      "tank/backup/persist".useTemplate = [ "bulk" ];
      # tank/torrents: re-downloadable. tank/backup/dumps: dated files, the
      # pg-dump CronJobs (home-ops) prune them.
    };
  };

  # fast/* to tank/backup/fast, nightly: a second copy of every app on other
  # disks. After the pg-dump CronJobs (03:00), before Recyclarr (04:30).
  services.syncoid = {
    enable = true;
    interval = "03:30";
    commands.fast = {
      source = "fast";
      target = "tank/backup/fast";
      # So a future fast/* is picked up on its own. --skip-parent: `fast`
      # itself holds nothing, and tank/backup/fast must stay a plain parent.
      recursive = true;
      # Not raw (no -w): each replica re-encrypts under tank's key and mounts
      # with the rest of tank. A raw replica would keep fast's key as its own
      # encryption root, with keylocation=prompt, and NixOS would then ask for
      # it at every boot. The offsite machine is where raw belongs: it can
      # raw-send these replicas as they are.
      #
      # Syncoid's sync snapshot is the incremental base: sanoid never prunes
      # it, and syncoid only drops the old one once the new one has landed, so
      # a long outage can't lose the base. Hourlies stay on `fast`; @pre-* are
      # by hand, and on the replica nothing would ever prune them.
      extraArgs = [
        "--skip-parent"
        "--exclude-snaps=_hourly$"
        "--exclude-snaps=^pre-"
      ];
      # -u: this unprivileged user can't mount, so a new replica would fail;
      # the ExecStartPost mounts it instead. readonly: a restore can't go the
      # wrong way, and a stray write would be rolled back by the next run. Set
      # on each child, since a read-only parent can't get new mountpoints.
      recvOptions = "u o readonly=on";
      # The module's list, plus what syncoid needs on the target: destroy for
      # the old sync snapshot (without it they pile up), readonly for -o above.
      localTargetAllow = [
        "change-key"
        "compression"
        "create"
        "destroy"
        "mount"
        "mountpoint"
        "readonly"
        "receive"
        "rollback"
      ];
      service = {
        unitConfig.OnFailure = [ "backup-failed@%N.service" ];
        serviceConfig = {
          # The module leaves it `simple`: "started" would come at once, and the
          # mount below would run before syncoid has received anything.
          Type = "oneshot";
          # `-`: a mount that fails doesn't undo a backup that succeeded.
          ExecStartPost = "-+${config.boot.zfs.package}/bin/zfs mount -a";
        };
      };
    };
  };

  # /persist is btrfs, so syncoid can't read it. A read-only btrfs snapshot
  # first: k3s's SQLite datastore is live, and rsync over a moving file would
  # copy a torn database. rsync rather than `btrfs send` into a file: plain
  # files on the far side, restorable one by one and without btrfs, and
  # sanoid's snapshots of the target (`bulk`) are the history. 23:30, so
  # sanoid's daily (midnight UTC) holds this night's copy.
  # This can't replace the keys in /persist/keys: tank/backup/persist is
  # encrypted with tank.key, so they need a copy off this box (MIGRATION.md §8).
  systemd.services.persist-backup = {
    description = "Copy a snapshot of /persist to tank/backup/persist";
    unitConfig = {
      # Never into the wiped root, if tank isn't there.
      RequiresMountsFor = [
        "/persist"
        "/srv/backup/persist"
      ];
      OnFailure = [ "backup-failed@%N.service" ];
    };
    path = [
      pkgs.btrfs-progs
      pkgs.rsync
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      snap=/persist/.backup-snapshot
      # Left behind by a run that was killed.
      if [ -e "$snap" ]; then btrfs subvolume delete "$snap"; fi
      btrfs subvolume snapshot -r /persist "$snap"
      trap 'btrfs subvolume delete "$snap"' EXIT
      # Left out: container images (pulled again) and the journal.
      rsync -aHAX --numeric-ids --one-file-system --delete --delete-excluded \
        --exclude=/var/lib/rancher/k3s/agent/containerd/ \
        --exclude=/var/log/journal/ \
        "$snap/" /srv/backup/persist/
    '';
  };
  systemd.timers.persist-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "23:30";
      Persistent = true;
    };
  };

  # A failed host backup pushes to ntfy like ZED does, cluster up or not.
  systemd.services."backup-failed@" = {
    description = "Report failed backup unit %i to ntfy";
    path = [ pkgs.curl ];
    scriptArgs = "%i";
    serviceConfig.Type = "oneshot";
    script = ''
      curl -fsS --retry 3 -H "Title: def-jam: $1 failed" -H "Priority: high" \
        -d "journalctl -u $1" "https://ntfy.sh/$(cat ${config.sops.secrets.ntfy-topic.path})"
    '';
  };

  # The pg-dump CronJobs (home-ops) run as Postgres's uid 26, and a hostPath
  # volume keeps the owner it has. Dumps hold password hashes: not world-readable.
  systemd.tmpfiles.settings."10-pg-dumps"."/srv/backup/dumps".d = {
    user = "26";
    group = "26";
    mode = "0750";
  };
}
