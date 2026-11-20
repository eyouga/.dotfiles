{ config, pkgs, ... }:
{
  # A failed unit pushes to ntfy like ZED does, cluster up or not. Units opt in
  # with `OnFailure = [ "unit-failed@%N.service" ]` (backups.nix, upgrades.nix).
  systemd.services."unit-failed@" = {
    description = "Report failed unit %i to ntfy";
    path = [ pkgs.curl ];
    scriptArgs = "%i";
    serviceConfig.Type = "oneshot";
    script = ''
      curl -fsS --retry 3 -H "Title: def-jam: $1 failed" -H "Priority: high" \
        -d "journalctl -u $1" "https://ntfy.sh/$(cat ${config.sops.secrets.ntfy-topic.path})"
    '';
  };
}
