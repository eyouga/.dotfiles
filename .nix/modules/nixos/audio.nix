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
    alsa-utils # aplay/amixer -- needed to see ALSA cards directly, e.g. the FireWire interface
  ];
}
