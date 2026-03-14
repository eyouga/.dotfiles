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
    ../../modules/user.nix
    ../../modules/packages.nix
    ../../modules/nixos/locale.nix
    ../../modules/nixos/packages.nix
    ../../modules/nixos/maintenance.nix
    ../../modules/nixos/configuration.nix
  ];

  networking.hostName = "def-jam";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.05";

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
    };
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

  users.users.eyouga.extraGroups = [
    "networkmanager"
    "i2c"
    "adbusers"
  ];
}
