# def-jam

The home server: NixOS with k3s, everything above k3s applied by Flux from
[home-ops](https://github.com/eyouga/home-ops).

## Hardware

- AMD Threadripper 2950X on an ASRock X399 Taichi, 64 GB of RAM.
- NVIDIA RTX 2070 (Turing: NVENC H.264/HEVC, no AV1), for Jellyfin's transcoding.
- Two Intel I211 NICs (`igb`): `enp6s0` is the cabled one, and can wake on LAN. The
  onboard Wi-Fi (Intel 3168) is unused, and logs PCIe correctable errors at boot.
- No TPM in use: the board's firmware TPM is off.

## Disks and pools

`disko-config.nix` defines everything, by-id names included; its header says how to
install and how to replace a disk.

| Disks | Holds |
|---|---|
| NVMe | LUKS, then btrfs: `/nix`, `/persist`, and a root wiped at every boot |
| 2 SSDs | `fast`, a ZFS mirror: every k8s volume, databases in their own dataset |
| 4 IronWolf 4 TB | `tank`, RAIDZ2: Nextcloud's files, the media and torrents (`tank/data`), and the backups |

Every ZFS dataset is natively encrypted, with its key in `/persist/keys`. `zfs.nix`
holds the pools' settings; `backups.nix` the snapshots, the nightly replica of
`fast` on `tank`, and the nightly copy of `/persist`. Restores are in home-ops'
`docs/operations.md`.

In `zpool status tank`, the IronWolfs show as `wwn-…-part1` names, not the `ata-…`
by-ids `disko-config.nix` uses.

## Boot

UEFI, systemd-boot, Secure Boot off. The NVMe's LUKS passphrase is typed at every
boot, over SSH to the initrd (`network.nix` says how); there is no TPM unlock, by
choice. Root and `/home` are wiped at boot: what survives is listed in
`../../modules/nixos/impermanence.nix`.

**The keys are the one thing a backup can't replace.** The pool keys and the age key
(sops-nix's, derived from the SSH host key) live on the NVMe; the backup of
`/persist` sits on `tank`, encrypted with `tank`'s own key. So a copy of the keys
belongs in a password manager, off this machine: without it, losing the NVMe makes
every pool unreadable.

## Updates

- Every night at 02:00 the system upgrades itself from this repository on GitHub
  (`../../modules/nixos/maintenance.nix`). A change that isn't pushed is undone.
- k3s is pinned to its minor version (`upgrades.nix`): a new Kubernetes minor is a
  decision, not a weekly bump.
- The phone hears about a failed upgrade or backup (`notify.nix`), a reboot the new
  kernel needs, and a system that has stopped getting updates (`upgrades.nix`).
- A new ZFS dataset: `zfs create` it **before** pushing its `fileSystems` entry, or the
  mount fails.
