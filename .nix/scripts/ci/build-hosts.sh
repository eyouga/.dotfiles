#!/usr/bin/env bash
# What the nightly upgrade would do, before it does: def-jam's whole system,
# built where it can be (x86_64-linux), evaluated elsewhere. No secrets: sops-nix
# only checks that its file holds the keys it names. Every other host is evaluated,
# the Mac included (Linux can evaluate darwin): a renamed option or a removed
# package shows here, not at the next rebuild.
set -euo pipefail
cd "$(dirname "$0")/../.."
if [ "$(nix eval --impure --raw --expr builtins.currentSystem)" = x86_64-linux ]; then
  nix build --no-link --print-build-logs '.#nixosConfigurations.def-jam.config.system.build.toplevel'
fi
names='c: builtins.concatStringsSep " " (builtins.attrNames c)'
for h in $(nix eval --raw .#nixosConfigurations --apply "$names"); do
  echo "$h: $(nix eval --raw ".#nixosConfigurations.$h.config.system.build.toplevel.drvPath")"
done
for h in $(nix eval --raw .#darwinConfigurations --apply "$names"); do
  echo "$h: $(nix eval --raw ".#darwinConfigurations.$h.system.drvPath")"
done
