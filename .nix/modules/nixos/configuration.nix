{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  #package config
  nix.package = pkgs.nix;
  nixpkgs.config.allowUnfree = true;

  # Enable Nix flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };

    kernelModules = [
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

  services.fwupd.enable = true;

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  services.printing.enable = true;

  networking = {
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
    # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
    # networking.interfaces.wlp11s0.useDHCP = lib.mkDefault true;
    networking.networkmanager.enable = true;
  };

  users.users.eyouga.extraGroups = [
    "networkmanager"
    "adbusers"
  ];

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      AllowUsers = [ "eyouga" ];
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "no";
    };
  };

  virtualisation.docker.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
