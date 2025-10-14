{ config, pkgs, ... }:
{

  #package config
  nix.package = pkgs.nix;
  nixpkgs.config.allowUnfree = true;
  programs.nix-index.enable = true;
  # Enable Nix flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.i2c.enable = true;
  services.fwupd.enable = true;

  console.useXkbConfig = true;
  time.timeZone = "Europe/Paris";
  services.xserver.xkb = {
    layout = "fr";
    options = "eurosign:e,caps:escape,ctrl:swapcaps";
  };
  i18n = {
    defaultLocale = "fr_FR.UTF-8";
    extraLocaleSettings = {
      LC_MESSAGES = "en_US.UTF-8";
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  services.printing.enable = true;

  networking.networkmanager.enable = true;

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

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  virtualisation.docker.enable = true;

  users.users.eyouga.extraGroups = [
    "networkmanager"
    "adbusers"
  ];
}
