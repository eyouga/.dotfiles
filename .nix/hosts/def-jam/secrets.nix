{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # Encrypted for the Mac's age key and def-jam's SSH host key (.sops.yaml).
  # Edit from the Mac: `sops edit hosts/def-jam/secrets.sops.yaml`.
  sops = {
    defaultSopsFile = ./secrets.sops.yaml;
    # Read from /persist itself: sops-nix decrypts during activation, and
    # impermanence's bind of /etc/ssh may not be in place yet.
    age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    gnupg.sshKeyPaths = [ ];
    # ZED's ntfy topic (zfs.nix). Root-only, in /run/secrets.
    secrets.ntfy-topic = { };
  };
}
