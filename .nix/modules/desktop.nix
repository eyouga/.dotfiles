{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./configuration.nix
  ];
  programs.nix-index.enable = true;
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    android-tools
    inputs.fjordlauncher.packages."${pkgs.stdenv.hostPlatform.system}".fjordlauncher
    inputs.zen-browser.packages."${stdenv.hostPlatform.system}".twilight
    localsend
    scrcpy
    yt-dlp
  ];

  # add nerd fonts
  fonts.packages = with pkgs; [
    nerd-fonts.droid-sans-mono
    nerd-fonts.hack
    nerd-fonts.iosevka
  ];
}
