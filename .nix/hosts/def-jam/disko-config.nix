# def-jam's disks (MIGRATION.md §3.4): NVMe for the OS, `fast` (SSD mirror)
# for every k8s volume, `tank` (RAIDZ2) for bulk data.
#
# Before running disko, from the installer:
#   1. Replace every REPLACE-ME below with names from `ls -l /dev/disk/by-id/`
#      (by-id, never /dev/sdX: those shift when a USB disk is plugged in).
#   2. Unplug the old TrueNAS USB disks. disko formats what it's pointed at.
#   3. Create the ZFS keys disko reads during creation:
#        head -c 32 /dev/urandom > /tmp/fast.key
#        head -c 32 /dev/urandom > /tmp/tank.key
#      and after disko, copy them to /mnt/persist/keys/ (mode 0400). The pools
#      are switched to that location as soon as they're created.
let
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
        device = "/dev/disk/by-id/REPLACE-ME-nvme";
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

      ssd1 = zfsMember "fast" "/dev/disk/by-id/REPLACE-ME-ssd1";
      ssd2 = zfsMember "fast" "/dev/disk/by-id/REPLACE-ME-ssd2";

      hdd1 = zfsMember "tank" "/dev/disk/by-id/REPLACE-ME-hdd1";
      hdd2 = zfsMember "tank" "/dev/disk/by-id/REPLACE-ME-hdd2";
      hdd3 = zfsMember "tank" "/dev/disk/by-id/REPLACE-ME-hdd3";
      hdd4 = zfsMember "tank" "/dev/disk/by-id/REPLACE-ME-hdd4";
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
