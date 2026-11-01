{ config, ... }:
let
  # Same address in the initrd and the running system, so unlocking and
  # everyday SSH both go to 192.168.1.80.
  lan = {
    matchConfig.Name = "en*";
    address = [ "192.168.1.80/24" ];
    gateway = [ "192.168.1.254" ];
    # Not blocky: the host must still resolve (to pull images, to fix things)
    # when the cluster that serves LAN DNS is down.
    dns = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };
in
{
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks."10-lan" = lan;
    # en* also matches the spare, uncabled enp4s0; without this,
    # wait-online waits for it until it times out and fails.
    wait-online.anyInterface = true;
  };

  # Unlock the NVMe over SSH after a power cut: `ssh -p 2222 root@192.168.1.80`,
  # then `systemd-tty-ask-password-agent` asks for the LUKS passphrase.
  boot.initrd = {
    # The X399 boards' Intel I211 NIC. Check with `lspci -k` on the installer.
    availableKernelModules = [ "igb" ];
    network = {
      enable = true;
      ssh = {
        enable = true;
        # Not 22: the initrd has its own host key, and a different port keeps
        # it from clashing with the real one in known_hosts.
        port = 2222;
        # The initrd sits unencrypted on the ESP, so this key must never be
        # the main host key. Create it at install time:
        #   ssh-keygen -t ed25519 -N "" -f /mnt/persist/initrd/ssh_host_ed25519_key
        hostKeys = [ "/persist/initrd/ssh_host_ed25519_key" ];
        authorizedKeys = config.users.users.eyouga.openssh.authorizedKeys.keys;
      };
    };
    systemd.network = {
      enable = true;
      networks."10-lan" = lan;
    };
  };
}
