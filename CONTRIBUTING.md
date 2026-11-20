# Contributing

The rules this repository keeps, for anyone changing it, people and tools alike.
[home-ops](https://github.com/eyouga/home-ops) keeps the same ones, plus its
cluster's own.

## Docs and comments

1. **The repository explains itself.** With only this repository you can understand
   the hosts, rebuild them and restore them: the README files. Private details (home
   address and IP, people's account names, weaknesses not yet fixed) stay out.
2. **A comment says why it is this way now, not how it got here.** History belongs
   in git. The test: if this comment vanished, could someone make a wrong change?
3. **Each fact has one owner.** Docs point to the file instead of copying its value.
   Code repeats a fact only when it must, and then a check keeps the copies in
   agreement.
4. **Anything temporary says when it goes:** `TEMPORARY: until <condition>`, next to
   it. CI rejects a marker without `until`.

## Code

5. **If a tool can check a rule, CI checks it.** Every language has a formatter and a
   linter (`.nix/scripts/ci/lint.sh`); settings live in config files
   (`.editorconfig`, `.luacheckrc`, `.nix/statix.toml`). A finding is fixed, or
   silenced on its line with the reason.
6. **Things of the same kind have the same shape:** one directory per host, modules
   by platform.
7. **Plain beats clever.** A file you can read top to bottom beats an abstraction.
   Share only what must change together.
8. **Small units, one job each.** A script over about 150 lines says why in its
   header. Split by job, never by length alone.
9. **Dead code is deleted, not commented out.** No TODO or FIXME: do it, mark it
   `TEMPORARY: until …`, or put it on the open list.
10. **Every dependency is pinned and something updates it:** flake inputs through
    `flake.lock` (Renovate, weekly), neovim's plugins through `lazy-lock.json`
    (`:Lazy update`). zsh's plugins, cloned by zinit at shell start, are the written
    exception. A pull request open over 30 days says why on it.

## Changes

11. **One change per commit.** Subject `scope: what changed`: `nix (def-jam):`,
    `nix:`, `nvim:`, `config:`…, under 72 characters, one thought. The why goes in
    the body. Experiments go on a branch. History is never rewritten.
12. **Cleanup doesn't change behaviour, and proves it:** `.nix/scripts/drv-diff.sh`
    names no host. Anything that changes behaviour goes in its own commit.
13. **Direct pushes go through the pre-push hook** (`git config core.hooksPath
    .nix/scripts/hooks`). Changes that could lock someone out of a host go through a
    pull request. Never push with `--no-verify`.
14. **A new file or folder at the root needs a line in `.stow-local-ignore`**, unless
    it belongs in `$HOME`.
15. **Secrets only as `*.sops.yaml`** (sops-nix), encrypted before they touch the disk.

## Hosts and recovery

16. **Git explains everything on a host except data.** What can't be in git (keys,
    passwords, firmware settings) is listed with the command that sets it.
17. **Nothing deletes data on its own** apart from the retention written in git. Any
    other irreversible removal is a command for the owner, run once its condition is
    met, after whatever refers to the thing is gone.
18. **Every failure reaches the phone, with what to do; every recovery is rehearsed,
    with the date next to its procedure.**
19. **Hygiene is reviewed every month,** for what CI can't see.
