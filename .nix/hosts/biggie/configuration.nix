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
    ../../modules/nixos/android.nix
    ../../modules/nixos/packages.nix
    ../../modules/nixos/maintenance.nix
    ../../modules/nixos/configuration.nix
    ../../modules/wm/plasma.nix
  ];

  networking.hostName = "biggie";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "25.05";

  boot = {
    kernelModules = [
      "firewire-ohci"
      "firewire-core"
      "kvm-amd"
    ];
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

  environment.systemPackages = with pkgs; [
    easyeffects
    ffado
    ffado-mixer
  ];

  users.users.eyouga.extraGroups = [
    "networkmanager"
    "i2c"
  ];
}
