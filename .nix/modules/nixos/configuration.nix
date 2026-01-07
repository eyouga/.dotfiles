{ config, pkgs, ... }:
{

  #package config
  nix.package = pkgs.nix;
  nixpkgs.config.allowUnfree = true;

  # Enable Nix flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  hardware.i2c.enable = true;
  services.fwupd.enable = true;

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  services.printing.enable = true;

  networking.networkmanager.enable = true;
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
}
