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
    # def-jam's cluster is driven from here: SOPS-encrypted secrets, Flux
    # bootstrap, and kubectl against the k3s API.
    age
    fluxcd
    gh
    kubectl
    sops
  ];
}
