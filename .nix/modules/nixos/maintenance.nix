{ config, ... }:
{
  system.autoUpgrade = {
    enable = true;
    flake = "github:eyouga/.dotfiles?dir=.nix";
    flags = [
      "--print-build-logs"
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise = {
    automatic = true;
    dates = [ "03:45" ];
  };
}
