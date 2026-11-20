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
  services.k3s.package = pkgs.k3s_1_36;

  systemd.services.nixos-upgrade.unitConfig = {
    # A failed upgrade leaves the old system running, quietly unpatched.
    OnFailure = [ "unit-failed@%N.service" ];
    OnSuccess = [ "dotfiles-follow-deploy.service" ];
  };

  # ~/.dotfiles, which stow links into the home at boot (configuration.nix),
  # moves to the commit the upgrade just deployed. Nix's fetcher cache still
  # holds which one that was; the long tarball-ttl keeps nix from asking GitHub
  # again, where master may have moved since. Local changes there stop it.
  systemd.services.dotfiles-follow-deploy = {
    description = "Check out the deployed commit in ~/.dotfiles";
    unitConfig = {
      OnFailure = [ "unit-failed@%N.service" ];
      ConditionPathExists = "/home/eyouga/.dotfiles/.git";
    };
    path = [
      config.nix.package
      pkgs.git
      pkgs.jq
      pkgs.util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/home/eyouga/.dotfiles";
    };
    script = ''
      rev=$(nix flake metadata --json --option tarball-ttl 4294967295 \
        '${config.system.autoUpgrade.flake}' | jq -er .revision)
      as_eyouga() { runuser -u eyouga -- "$@"; }
      if [ -n "$(as_eyouga git status --porcelain)" ]; then
        echo "local changes: ~/.dotfiles left at $(as_eyouga git rev-parse --short HEAD)" >&2
        exit 1
      fi
      as_eyouga git fetch --quiet https://github.com/eyouga/.dotfiles.git "$rev"
      as_eyouga git checkout --quiet --detach "$rev"
      # New files get their links now; links to removed ones go with the next
      # boot's fresh home.
      systemctl start stow-dotfiles.service
    '';
  };

  # Each boot needs the LUKS passphrase, so reboots stay a person's job: tell them.
  # Daily at a waking hour, not after the 02:00 switch. Only the kernel and its
  # modules count: the running system keeps using the old ones (and a new nvidia
  # or ZFS userland against an old module breaks NVENC or `zfs` until the reboot),
  # whereas a new initrd isn't running anywhere, the next boot just uses it. It
  # changes with almost every nixpkgs bump, so counting it would cry wolf weekly.
  # The second check is the other way this automation can fail silently: Renovate or the
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
      # system, then weekly: find rounds ages down, and a week later the file is a
      # moment short of 7 days, so +5 (+6 made it every 8 days).
      sent=/run/host-upkeep-reboot-sent
      if [ "$booted$booted_mods" != "$running$running_mods" ]; then
        if [ "$(cat "$sent" 2>/dev/null)" != "$running_mods" ] \
          || [ -n "$(find "$sent" -mtime +5 2>/dev/null)" ]; then
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
