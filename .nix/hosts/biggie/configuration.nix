{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko-config.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/games.nix
    ../../modules/nixos/waydroid.nix
    ../../modules/nixos/maintenance.nix
    ../../modules/wm/plasma.nix
  ];

  networking.hostName = "biggie";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "25.05";

  # FireWire, if the Saffire PRO 14 is ever revived: the root is LUKS, so
  # boot.initrd.luks.mitigateDMAAttacks (default true) blacklists
  # firewire_ohci/_core/_sbp2, and nothing on the bus is ever autodetected.
  # Re-enable with
  #   boot.initrd.luks.mitigateDMAAttacks = false;
  #   boot.blacklistedKernelModules = [ "firewire_sbp2" ];
  # which keeps SBP-2 -- the protocol that actually grants raw DMA -- disabled.
  # That much was verified working: the modules autoload and udev binds cleanly.
  # The interface itself is the open question. On 2026-09-20 it enumerated but
  # answered "no ack" to every snd_dice transaction on kernels 7.2.3, 7.1.5 and
  # 6.12.108 alike, and by the end of the evening it had stopped appearing on
  # the bus at all. Fix the hardware before touching this config again.
  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = {
      kvm-amd = true;
    };
    extraModulePackages = [ ];
  };

  hardware = {
    i2c.enable = true;
    bluetooth = {
      enable = true; # enables support for Bluetooth
      powerOnBoot = true; # powers up the default Bluetooth controller on boot
    };
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  services.lact.enable = true;
  networking = {
    useDHCP = false;
    networkmanager.enable = true;
  };

  programs.obs-studio = {
    enable = true;

    plugins = with pkgs.obs-studio-plugins; [
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi # optional AMD hardware acceleration
      obs-gstreamer
      obs-vkcapture
    ];
  };

  users.users.eyouga.extraGroups = [
    "networkmanager"
    "i2c"
    "adbusers"
  ];
}
