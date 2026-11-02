#!/usr/bin/env bash
# What the nightly upgrade would do, before it does: def-jam's whole system,
# built. No secrets: sops-nix only checks that its file holds the keys it names.
# biggie auto-upgrades from the same lock, so it's at least evaluated.
set -euo pipefail
cd "$(dirname "$0")/../.."
nix build --no-link --print-build-logs '.#nixosConfigurations.def-jam.config.system.build.toplevel'
nix eval --raw '.#nixosConfigurations.biggie.config.system.build.toplevel.drvPath'
echo
