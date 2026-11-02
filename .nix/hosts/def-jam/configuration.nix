{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko-config.nix
    ./network.nix
    ./secrets.nix
    ./upgrades.nix
    ./zfs.nix
    ../../modules/nixos/maintenance.nix
    ../../modules/nixos/configuration.nix
    ../../modules/nixos/impermanence.nix
    ../../modules/nixos/k3s.nix
    ../../modules/nixos/nvidia.nix
  ];

  networking.hostName = "def-jam";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.05";

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
    };
    kernelModules = {
      kvm-amd = true;
    };
    extraModulePackages = [ ];
  };

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    # The RTX 2070 in pods (Jellyfin, the GPU exporter): writes the CDI spec
    # in /var/run/cdi at boot. k3s's runtime for it is below.
    nvidia-container-toolkit.enable = true;
  };

  # k3s registers a containerd handler for each NVIDIA runtime it finds in its
  # PATH, in the right config format and cgroup mode. The one used here is
  # `nvidia-cdi` (nvidia-container-runtime.cdi), which turns a pod's
  # NVIDIA_VISIBLE_DEVICES into devices from the CDI spec above. Its
  # RuntimeClass lives in home-ops. (A containerdConfigTemplate doesn't fit:
  # NixOS writes config.toml.tmpl, which k3s pairs with its v2 base, and
  # hand-written runtime entries drift from k3s's own settings.)
  systemd.services.k3s.path = [ (lib.getOutput "tools" pkgs.nvidia-container-toolkit) ];

  # Flux owns everything above k3s (MIGRATION.md §3); these only make the
  # bundled extras step aside for the upstream projects.
  services.k3s.extraFlags = [
    "--disable=traefik"
    "--disable=servicelb"
    "--default-local-storage-path=/var/lib/k8s-volumes"
  ];
  # Without this, k3s can start before ZFS mounts fast/k8s and write PVCs into
  # the root subvolume, which the next boot wipes.
  systemd.services.k3s.unitConfig.RequiresMountsFor = [
    "/var/lib/k8s-volumes"
    "/var/lib/k8s-volumes/databases"
  ];
  # Pod-to-pod and pod-to-host traffic (DNS, the API server) over flannel.
  networking.firewall.trustedInterfaces = [
    "cni0"
    "flannel.1"
  ];

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/rancher" # k3s datastore, containerd images
      "/etc/rancher" # kubeconfig and node password: lose it and the node can't rejoin
    ];
    # The rest of /home/eyouga is wiped at every boot. Clone the dotfiles into
    # /mnt/persist/home/eyouga/.dotfiles at install time.
    users.eyouga.directories = [
      ".dotfiles" # this flake (nh points here) and everything stow links
      {
        directory = ".ssh";
        mode = "0700";
      } # known_hosts; .ssh/config is a stow link inside it
      ".local/state/zsh" # history (.zshrc keeps it here for this reason)
      ".local/share/zinit" # zsh plugins: a shell still starts with the network down
      ".local/share/nvim" # lazy.nvim plugins
      ".local/state/nvim" # undo history, shada
    ];
  };

  # Recreate the stow links in the freshly wiped home. --no-folding: with no
  # ~/.config yet, stow would link ~/.config itself into the repo, and every
  # app's settings would land in the dotfiles.
  systemd.services.stow-dotfiles = {
    description = "Link ~/.dotfiles into the wiped home";
    wantedBy = [ "multi-user.target" ];
    before = [ "sshd.service" ];
    unitConfig = {
      RequiresMountsFor = [ "/home/eyouga/.dotfiles" ];
      ConditionPathExists = "/home/eyouga/.dotfiles/.zshrc"; # not cloned yet: skip
    };
    serviceConfig = {
      Type = "oneshot";
      User = "eyouga";
      WorkingDirectory = "/home/eyouga/.dotfiles";
    };
    path = [ pkgs.stow ];
    script = "stow --no-folding --target=/home/eyouga .";
  };
}
