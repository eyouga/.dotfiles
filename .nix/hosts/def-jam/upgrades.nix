{ config, pkgs, ... }:
let
  push = title: body: ''
    curl -fsS --retry 3 -H "Title: ${title}" -d "${body}" \
      "https://ntfy.sh/$(cat ${config.sops.secrets.ntfy-topic.path})"
  '';
in
{
  # flake.lock moves by itself every week and the 02:00 upgrade applies it, so
  # Kubernetes must not move with it: nixpkgs' `k3s` follows the newest minor. This
  # takes patches only; a new minor is a decision, in this line.
  services.k3s.package = pkgs.k3s_does_not_exist;

  # A failed upgrade leaves the old system running, quietly unpatched.
  systemd.services.nixos-upgrade.unitConfig.OnFailure = [ "unit-failed@%N.service" ];

  # Each boot needs the LUKS passphrase, so reboots stay a person's job: tell them.
  # Daily at a waking hour, not after the 02:00 switch. Only the kernel and its
  # modules count: the running system keeps using the old ones (and a new nvidia
  # or ZFS userland against an old module breaks NVENC or `zfs` until the reboot),
  # whereas a new initrd isn't running anywhere, the next boot just uses it. It
  # changes with almost every nixpkgs bump, so counting it would cry wolf weekly.
  # The second check is the other way this phase can fail silently: Renovate or the
  # upgrade stopped, and nothing is left to go red.
  systemd.services.host-upkeep-check = {
    description = "Tell the phone if def-jam needs a reboot or stopped getting updates";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [
      pkgs.coreutils
      pkgs.curl
      pkgs.findutils
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      booted=$(readlink -f /run/booted-system/kernel)
      running=$(readlink -f /run/current-system/kernel)
      booted_mods=$(readlink -f /run/booted-system/kernel-modules)
      running_mods=$(readlink -f /run/current-system/kernel-modules)
      # In /run on purpose: the reboot this asks for is what clears it. Once per new
      # system, then weekly.
      sent=/run/host-upkeep-reboot-sent
      if [ "$booted$booted_mods" != "$running$running_mods" ]; then
        if [ "$(cat "$sent" 2>/dev/null)" != "$running_mods" ] \
          || [ -n "$(find "$sent" -mtime +6 2>/dev/null)" ]; then
          from=$(basename "$(dirname "$booted")")
          to=$(basename "$(dirname "$running")")
          ${push "def-jam needs a reboot" "Running \${from#*-}, installed \${to#*-} (kernel or its modules). After the reboot: ssh -t -p 2222 root@192.168.1.80 systemd-tty-ask-password-agent"}
          echo "$running_mods" >"$sent"
        fi
      fi

      # nixos-version ends in nixpkgs' date: 26.11.20261028.e62746b.
      version=$(cat /run/current-system/nixos-version)
      date=$(echo "$version" | cut -d. -f3)
      age=$(( ($(date +%s) - $(date -d "$date" +%s)) / 86400 ))
      if [ "$age" -gt 21 ]; then
        ${push "def-jam stopped getting updates" "nixpkgs here is $age days old. Look at Renovate's dashboard in the dotfiles repo, and journalctl -u nixos-upgrade."}
      fi
    '';
  };
  systemd.timers.host-upkeep-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "09:30";
      Persistent = true;
    };
  };
}
