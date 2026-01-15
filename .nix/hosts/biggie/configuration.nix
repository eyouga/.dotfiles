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
    ../../modules/nixos/audio.nix
    ../../modules/nixos/games.nix
    ../../modules/nixos/locale.nix
    ../../modules/nixos/waydroid.nix
    ../../modules/nixos/packages.nix
    ../../modules/nixos/maintenance.nix
    ../../modules/nixos/configuration.nix
    ../../modules/wm/plasma.nix
  ];

  networking.hostName = "biggie";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "25.05";

  programs = {
    kdeconnect.enable = true;
  };

  boot = {
    blacklistedKernelModules = [
      "ohci1394"
      "raw1394"
      "video1394"
      "sbp2"
      # "snd-dice"
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

  systemd.services.firewire-modules = {
    description = "Load FireWire modules late so the soundcard gets detected";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "${pkgs.kmod}/bin/modprobe firewire-ohci"
        "${pkgs.kmod}/bin/modprobe firewire-core"
        "${pkgs.kmod}/bin/modprobe firewire-sbp2"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    easyeffects
    ffado
    ffado-mixer
  ];

  users.users.eyouga.extraGroups = [
    "networkmanager"
    "i2c"
    "adbusers"
  ];
}
