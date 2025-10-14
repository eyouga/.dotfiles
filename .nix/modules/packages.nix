{
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    neovim
    nixfmt-rfc-style
    fzf
    eza
    zoxide
    stow
    zsh
    bottom
    git
    wget
    lazygit
    yt-dlp
  ];
}
