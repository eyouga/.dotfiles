{ config, pkgs, ... }:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = false;
    alsa.enable = true;
  };
  environment.systemPackages = with pkgs; [
    easyeffects
  ];
}
