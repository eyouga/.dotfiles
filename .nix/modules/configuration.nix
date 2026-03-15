{
  inputs,
  config,
  pkgs,
  ...
}:
{
  # Enable Nix flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs = {
    nix-index.enable = true;
    zsh.enable = true;
  };
  nixpkgs.config.allowUnfree = true;

  users.users.eyouga = {
    name = "eyouga";
    description = "Lucien Thany--Eynard";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJICpMMXQyNXOwaYKCEBIGvtgkVIZv9teE8DbwECVz6Y"
    ];
  };

  environment.systemPackages = with pkgs; [
    bottom
    eza
    fzf
    git
    lazygit
    minikube
    neovim
    nixfmt
    prettier
    stow
    tre-command
    wezterm
    wget
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
