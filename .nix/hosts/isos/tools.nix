# Install and rescue tools for both ISOs. cryptsetup, zfs, rsync, git and
# memtest86+ already come with nixpkgs' installer.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Disks
    ddrescue
    disko
    gptfdisk
    hdparm
    nvme-cli
    parted
    smartmontools
    testdisk

    # Firmware and hardware
    dmidecode
    efibootmgr
    lshw
    pciutils
    sbctl
    usbutils

    # Shell
    fd
    jq
    ripgrep
    tmux

    # Network
    dnsutils
    iperf3
    mtr
    nmap
    tcpdump

    # Nix
    nix-output-monitor
    nvd

    claude-code
  ];
}
