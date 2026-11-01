# def-jam's disks (MIGRATION.md §3.4): NVMe for the OS, `fast` (SSD mirror)
# for every k8s volume, `tank` (RAIDZ2) for bulk data.
#
# Disks are named by-id, never /dev/sdX: those shift when a USB disk is
# plugged in. Read off the machine from the live ISO on 2026-11-01.
#
# tank is short one IronWolf: the 4th died before the install. tank is
# still created 4-wide, with a sparse file standing in for hdd4, then that
# member is taken offline: RAIDZ2 running degraded, so one disk of
# redundancy (like RAIDZ1) until the replacement turns it into the real
# thing. RAIDZ1 could never become RAIDZ2 later; this can.
#
# Before running disko, from the installer:
#   1. Unplug the old TrueNAS USB disks. disko formats what it's pointed at.
#   2. Create the ZFS keys disko reads during creation:
#        head -c 32 /dev/urandom > /tmp/fast.key
#        head -c 32 /dev/urandom > /tmp/tank.key
#      and after disko, copy them to /mnt/persist/keys/ (mode 0400). The pools
#      are switched to that location as soon as they're created.
#   3. The stand-in for hdd4, 128 MiB smaller than an IronWolf so that any
#      4 TB disk can replace it (sparse: it takes no space):
#        truncate -s 4000652812288 /tmp/hdd4.img
#        sudo losetup -P /dev/loop9 /tmp/hdd4.img
# After disko, before anything is written to tank:
#   4. sudo zpool offline tank disk-hdd4-zfs
#      sudo losetup -d /dev/loop9 && rm /tmp/hdd4.img
# After nixos-install, before rebooting:
#   5. sudo zpool export fast tank
#      The pools were created under the installer's hostid; def-jam's own
#      (zfs.nix) only imports them at boot if they were exported cleanly.
#
# When the replacement disk arrives (`<new>` is its by-id name):
#   sudo sgdisk -R /dev/disk/by-id/<new> /dev/disk/by-id/ata-ST4000VN006-3CW104_WW6A8ZH3
#   sudo sgdisk -G -c 1:disk-hdd4-zfs /dev/disk/by-id/<new>
#   sudo zpool replace tank disk-hdd4-zfs /dev/disk/by-id/<new>-part1
# then point hdd4 below at it. The resilver rebuilds hdd4's share; tank
# is full RAIDZ2 when `zpool status tank` says ONLINE, listing the new disk
# by its by-id name. (All of this was rehearsed on virtual disks first.)
let
  nvme = "nvme-CT500P3SSD8_240746EDEFF3"; # Crucial P3 500 GB
  ssd1 = "ata-KINGSTON_SA400S37480G_50026B7785827EDC";
  ssd2 = "ata-KINGSTON_SA400S37480G_50026B778582838B";
  hdd1 = "ata-ST4000VN006-3CW104_WW6A8ZH3";
  hdd2 = "ata-ST4000VN006-3CW104_WW63K7YA";
  hdd3 = "ata-ST4000VN006-3CW104_WW639DKY";
  # The stand-in from step 3, until the replacement disk arrives.
  hdd4 = "/dev/loop9";

  byId = name: "/dev/disk/by-id/${name}";

  btrfsOpts = [
    "compress=zstd"
    "noatime"
  ];

  # One whole-disk GPT partition handed to a zpool.
  zfsMember = pool: device: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions.zfs = {
        size = "100%";
        content = {
          type = "zfs";
          inherit pool;
        };
      };
    };
  };

  # Shared by both pools; each dataset inherits it.
  poolFsOptions = pool: {
    compression = "lz4";
    atime = "off";
    xattr = "sa";
    acltype = "posixacl";
    encryption = "aes-256-gcm";
    keyformat = "raw";
    keylocation = "file:///tmp/${pool}.key";
    mountpoint = "none";
  };
in
{
  disko.devices = {
    disk = {
      nvme = {
        type = "disk";
        device = byId nvme;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "boot";
              name = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings = {
                  allowDiscards = true;
                  bypassWorkqueues = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-L"
                    "nixos"
                    "-f"
                  ];
                  # No /home subvolume: /home lives in root and is wiped with it
                  # (modules/nixos/impermanence.nix). No swap either: 64 G of
                  # RAM, a capped ARC, and kubelet expects swap off.
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = btrfsOpts;
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = btrfsOpts;
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = btrfsOpts;
                    };
                  };
                };
              };
            };
          };
        };
      };

      ssd1 = zfsMember "fast" (byId ssd1);
      ssd2 = zfsMember "fast" (byId ssd2);

      hdd1 = zfsMember "tank" (byId hdd1);
      hdd2 = zfsMember "tank" (byId hdd2);
      hdd3 = zfsMember "tank" (byId hdd3);
      hdd4 = zfsMember "tank" hdd4;
    };

    zpool = {
      fast = {
        type = "zpool";
        mode = "mirror";
        options.ashift = "12";
        rootFsOptions = poolFsOptions "fast";
        postCreateHook = "zfs set keylocation=file:///persist/keys/fast.key fast";
        datasets = {
          # local-path-provisioner's base: one directory per PVC.
          k8s = {
            type = "zfs_fs";
            mountpoint = "/var/lib/k8s-volumes";
          };
          # CNPG volumes; Postgres pages are 8K, so small records waste less.
          k8s-db = {
            type = "zfs_fs";
            mountpoint = "/var/lib/k8s-db";
            options.recordsize = "16K";
          };
        };
      };

      tank = {
        type = "zpool";
        mode = "raidz2";
        options.ashift = "12";
        rootFsOptions = poolFsOptions "tank";
        postCreateHook = "zfs set keylocation=file:///persist/keys/tank.key tank";
        datasets = {
          nextcloud = {
            type = "zfs_fs";
            mountpoint = "/srv/nextcloud";
          };
          media = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              recordsize = "1M"; # large, sequentially read files
            };
          };
          "media/films" = {
            type = "zfs_fs";
            mountpoint = "/srv/media/films";
          };
          "media/series" = {
            type = "zfs_fs";
            mountpoint = "/srv/media/series";
          };
          "media/music" = {
            type = "zfs_fs";
            mountpoint = "/srv/media/music";
          };
          torrents = {
            type = "zfs_fs";
            mountpoint = "/srv/torrents";
          };
          backup = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "backup/fast" = {
            type = "zfs_fs";
            mountpoint = "/srv/backup/fast";
          };
          "backup/persist" = {
            type = "zfs_fs";
            mountpoint = "/srv/backup/persist";
          };
          "backup/dumps" = {
            type = "zfs_fs";
            mountpoint = "/srv/backup/dumps";
          };
        };
      };
    };
  };
}
