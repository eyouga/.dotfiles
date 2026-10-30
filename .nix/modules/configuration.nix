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
    nh = {
      enable = true;
      # NH_FLAKE is read straight out of the environment, so a "~" in here is
      # never expanded -- it has to be absolute, and the prefix differs per
      # platform. The trailing slash is load-bearing too: the module asserts
      # the path must not end in ".nix", and this directory is named .nix.
      flake = "${if pkgs.stdenv.hostPlatform.isDarwin then "/Users" else "/home"}/eyouga/.dotfiles/.nix/";
    };
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
