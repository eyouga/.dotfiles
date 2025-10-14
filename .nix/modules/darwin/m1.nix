{
  config,
  pkgs,
  lib,
  home-manager,
  mac-app-util,
  ...
}:

{
  # Include extra architecture
  nix.extraOptions = ''
    extra-platforms = aarch64-darwin x86_64-darwin
  '';
}
