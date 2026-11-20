#!/usr/bin/env bash
# Every formatter and linter this repo has, on every tracked file of its kind.
# Settings live in .editorconfig (shfmt), .luacheckrc and .nix/statix.toml. A
# finding is fixed, or silenced on its line with the reason. .p10k.zsh is written
# by `p10k configure`, so only its syntax is checked.
set -euo pipefail
cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
failed=0
fail() {
  echo "FAIL: $*" >&2
  failed=1
}
mine=':!.nix/scripts/ci/lint.sh'

mapfile -t nix < <(git ls-files '*.nix')
nixfmt --check "${nix[@]}" || fail "nixfmt: run nixfmt on these"
deadnix --fail "${nix[@]}" || fail deadnix
(cd .nix && statix check .) || fail statix

mapfile -t lua < <(git ls-files '*.lua')
luacheck -q "${lua[@]}" || fail luacheck
stylua --check "${lua[@]}" || fail "stylua: run stylua on these"

mapfile -t sh < <(git ls-files '*.sh')
mapfile -t zsh < <(git ls-files .zshrc '*.zsh' ':!.p10k.zsh')
shellcheck "${sh[@]}" || fail shellcheck
shfmt -d "${sh[@]}" "${zsh[@]}" || fail "shfmt: run shfmt -w on these"
for f in "${zsh[@]}" .p10k.zsh; do zsh -n "$f" || fail "zsh -n $f"; done
actionlint || fail actionlint

# Open work is done, marked TEMPORARY with its end, or on the open list.
if git grep -n -w -E 'TODO|FIXME' -- . "$mine" ':!.p10k.zsh'; then
  fail "TODO or FIXME: do it, mark it 'TEMPORARY: until <condition>', or put it on the open list"
fi
if git grep -n 'TEMPORARY' -- . "$mine" | grep -v 'TEMPORARY: until '; then
  fail "a TEMPORARY marker without 'TEMPORARY: until <condition>'"
fi
exit $failed
