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
  environment.systemPackages = with pkgs; [
    android-tools
    inputs.fjordlauncher.packages."${pkgs.stdenv.hostPlatform.system}".fjordlauncher
    inputs.zen-browser.packages."${stdenv.hostPlatform.system}".beta
    localsend
    scrcpy
    yt-dlp
  ];
}
