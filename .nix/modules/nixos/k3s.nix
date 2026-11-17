{ config, ... }:
{
  networking.firewall.allowedTCPPorts = [
    # 6443, the API server: pods reach it over cni0, a trusted interface. The host
    # opens it to the LAN itself (def-jam: network.nix, link-local only over IPv6).
    # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];
  networking.firewall.allowedUDPPorts = [
    # 8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];
  services.k3s.enable = true;
  services.k3s.role = "server";
  # A list, so hosts can add their own flags (two lists merge, strings don't).
  services.k3s.extraFlags = [
    # "--debug" # Optionally add additional args to k3s
  ];
}
