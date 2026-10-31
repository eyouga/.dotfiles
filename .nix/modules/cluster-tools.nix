{ pkgs, ... }:
{
  # def-jam's cluster is driven with these: SOPS-encrypted secrets, Flux
  # bootstrap, and kubectl against the k3s API. Shared by the Mac and the
  # live ISOs, which bootstrap def-jam.
  environment.systemPackages = with pkgs; [
    age
    fluxcd
    gh
    kubectl
    sops
  ];
}
