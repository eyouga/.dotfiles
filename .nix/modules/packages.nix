{
  inputs,
  config,
  pkgs,
  ...
}:
{
  programs.nix-index.enable = true;
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    anki
    android-tools
    bottom
    eza
    fzf
    git
    git-credential-keepassxc
    inputs.fjordlauncher.packages."${pkgs.stdenv.hostPlatform.system}".fjordlauncher
    inputs.zen-browser.packages."${stdenv.hostPlatform.system}".twilight
    keepassxc
    lazygit
    minikube
    neovim
    nixfmt
    scrcpy
    stow
    wezterm
    wget
    yt-dlp
    zoxide
    zsh
  ];

  # add nerd fonts
  fonts.packages = with pkgs; [
    nerd-fonts.droid-sans-mono
    nerd-fonts.hack
    nerd-fonts.iosevka
  ];
}
