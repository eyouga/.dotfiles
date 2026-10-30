{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    R
    claude-code
    nh
  ];
}
