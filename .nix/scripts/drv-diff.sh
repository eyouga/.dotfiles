#!/usr/bin/env bash
# drv-diff.sh [<base>] : does a change alter what any host would build?
# Evaluates every host's system drvPath at <base> (default origin/master) and in the
# working tree, and names the hosts whose drvPath differs. No output and exit 0: the
# change is a refactor, nothing would rebuild. Evaluation only, so it runs on the Mac
# for every host. Uncommitted edits count; new files only once `git add`ed (flakes).
set -euo pipefail
repo=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
base=${1:-origin/master}
tmp=$(mktemp -d)
cleanup() {
  git -C "$repo" worktree remove --force "$tmp/base" 2>/dev/null || true
  rm -rf "$tmp"
}
trap cleanup EXIT
git -C "$repo" worktree add --quiet --detach "$tmp/base" "$base"

names='c: builtins.concatStringsSep " " (builtins.attrNames c)'
# The ISOs copy the flake's own source into the image (eyouga-dotfiles in
# hosts/isos/common.nix), so any commit changes them. That one script is blanked,
# on both sides, so what's left is what the change does.
nixos='c: let
    copies = c.config.systemd.services ? eyouga-dotfiles;
    blank = { systemd.services.eyouga-dotfiles.script = c.pkgs.lib.mkForce ""; };
  in (if copies then c.extendModules { modules = [ blank ]; } else c).config.system.build.toplevel.drvPath'
drvs() { # <flake>: one "<host> <drvPath>" line per host
  local h
  for h in $(nix eval --raw "$1#nixosConfigurations" --apply "$names"); do
    echo "$h $(nix eval --raw "$1#nixosConfigurations.$h" --apply "$nixos")"
  done
  for h in $(nix eval --raw "$1#darwinConfigurations" --apply "$names"); do
    echo "$h $(nix eval --raw "$1#darwinConfigurations.$h.system.drvPath")"
  done
}
for side in before:"$tmp/base" after:"$repo"; do
  name=${side%%:*} tree=${side#*:}
  if ! drvs "$tree/.nix" >"$tmp/$name" 2>"$tmp/$name.log"; then
    cat "$tmp/$name.log" >&2
    echo "drv-diff: $name doesn't evaluate" >&2
    exit 2
  fi
done

awk 'NR == FNR { was[$1] = $2; next }
  !($1 in was) { print "new:     " $1; next }
  was[$1] != $2 { print "differs: " $1 }
  { delete was[$1] }
  END { for (h in was) print "gone:    " h }' "$tmp/before" "$tmp/after" | sort >"$tmp/report"
[ ! -s "$tmp/report" ] || { cat "$tmp/report"; exit 1; }
