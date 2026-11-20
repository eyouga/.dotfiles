# VMs (libvirt, with a software TPM) and containers (podman, Docker-compatible)
# on a desktop. def-jam runs its containers in k3s and needs neither.
{ pkgs, ... }:
{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    spiceUSBRedirection.enable = true;
  };

  environment.systemPackages = with pkgs; [
    podman-compose
  ];

  users.users.eyouga.extraGroups = [
    "podman"
    "libvirtd"
  ];
}
