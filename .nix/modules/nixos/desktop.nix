{ config, ... }:
{
  services.printing.enable = true;

  services.flatpak.enable = true;

  programs.virt-manager.enable = true;
}
