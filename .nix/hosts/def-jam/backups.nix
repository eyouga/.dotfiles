# def-jam's backups, all on tank: snapshots (sanoid), a nightly replica of
# fast (syncoid), a nightly copy of /persist, and the folder the pg-dump
# CronJobs (home-ops) write to. Failures push through notify.nix.
{ config, pkgs, ... }:
{
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
      # Nextcloud's files, hourly too: scripts/rollback.sh takes its database and
      # code back to an hourly snapshot, and these should be able to meet them. Only
      # what changed costs space, and a daily already keeps a deleted file for a month.
      nextcloud-files = {
        hourly = 24;
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
      "tank/nextcloud".useTemplate = [ "nextcloud-files" ];
      # TEMPORARY: until tank/media is destroyed (the removal list).
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
      # Not snapshotted: tank/backup/dumps, dated files the pg-dump CronJobs
      # (home-ops) prune; and tank/torrents, re-downloadable and on the removal list.
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
      # zfs-mount-replicas mounts it instead. readonly: a restore can't go the
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
        unitConfig = {
          OnFailure = [ "unit-failed@%N.service" ];
          OnSuccess = [ "zfs-mount-replicas.service" ];
        };
        # The module leaves it `simple`: "started" would come at once, and
        # OnSuccess is only meaningful once syncoid has really finished.
        serviceConfig.Type = "oneshot";
      };
    };
  };

  # A new replica's first mount, for file-level restores from its .zfs/snapshot.
  # Its own unit: syncoid's has PrivateMounts, so even a `+` command mounts
  # inside that namespace, and the mount is gone when the unit ends.
  systemd.services.zfs-mount-replicas = {
    description = "Mount replicas syncoid just created";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.boot.zfs.package}/bin/zfs mount -a";
    };
  };

  # /persist is btrfs, so syncoid can't read it. A read-only btrfs snapshot
  # first: k3s's SQLite datastore is live, and rsync over a moving file would
  # copy a torn database. rsync rather than `btrfs send` into a file: plain
  # files on the far side, restorable one by one and without btrfs, and
  # sanoid's snapshots of the target (`bulk`) are the history. 23:30, so
  # sanoid's daily (midnight UTC) holds this night's copy.
  # This can't replace the keys in /persist/keys: tank/backup/persist is
  # encrypted with tank.key, so they need a copy off this box, kept by hand.
  systemd.services.persist-backup = {
    description = "Copy a snapshot of /persist to tank/backup/persist";
    unitConfig = {
      # Never into the wiped root, if tank isn't there.
      RequiresMountsFor = [
        "/persist"
        "/srv/backup/persist"
      ];
      OnFailure = [ "unit-failed@%N.service" ];
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

  # The pg-dump CronJobs (home-ops) run as Postgres's uid 26, and a hostPath
  # volume keeps the owner it has. Dumps hold password hashes: not world-readable.
  systemd.tmpfiles.settings."10-pg-dumps"."/srv/backup/dumps".d = {
    user = "26";
    group = "26";
    mode = "0750";
  };
}
