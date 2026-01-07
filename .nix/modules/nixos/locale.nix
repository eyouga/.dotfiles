{ config, ... }:
{
  time.timeZone = "Europe/Paris";
  i18n = {
    defaultLocale = "fr_FR.UTF-8";
    extraLocaleSettings = {
      LC_MESSAGES = "en_US.UTF-8";
    };
  };

  console.useXkbConfig = true;
  services.xserver.xkb = {
    layout = "fr";
    options = "eurosign:e,caps:escape,ctrl:swapcaps";
  };
}
