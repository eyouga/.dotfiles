{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../configuration.nix
    ../cluster-tools.nix
  ];

  environment.systemPackages = with pkgs; [
    R
    claude-code
  ];
}
