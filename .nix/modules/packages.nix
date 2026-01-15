{
  inputs,
  #  config,
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    neovim
    nixfmt
    wezterm
    minikube
    fzf
    eza
    zoxide
    stow
    anki
    zsh
    bottom
    git
    wget
    lazygit
    scrcpy
    android-tools
    yt-dlp
    inputs.zen-browser.packages."${stdenv.hostPlatform.system}".twilight
    inputs.fjordlauncher.packages."${pkgs.stdenv.hostPlatform.system}".fjordlauncher
  ];
}
