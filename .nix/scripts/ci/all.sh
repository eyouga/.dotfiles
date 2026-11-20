#!/usr/bin/env bash
# Everything CI checks, in one command, the same on the Mac:
# `nix develop ./.nix -c .nix/scripts/ci/all.sh`. Every check runs, so one log
# shows all that's wrong.
set -uo pipefail
ci=$(dirname "$0")
failed=0
for check in lint.sh build-hosts.sh; do
  echo "::group::$check"
  "$ci/$check" || {
    echo "FAIL: $check" >&2
    failed=1
  }
  echo "::endgroup::"
done
exit $failed
