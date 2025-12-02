{ config, ... }:

{
  networking = {
    knownNetworkServices = [
      "Wi-Fi"
      "Bluetooth PAN"
      "Thunderbolt Bridge"
    ];
    applicationFirewall = {
      enable = true;
      enableStealthMode = true;
      blockAllIncoming = false;
      allowSigned = true;
    };
  };
}
