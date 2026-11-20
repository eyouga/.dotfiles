# .dotfiles

My machines' configuration: the NixOS hosts and the Mac under `.nix/`, and the
rest (zsh, neovim, wezterm, karabiner, git, ssh) linked into `$HOME` by GNU stow.

| Path | What |
|---|---|
| `.nix/flake.nix` | the hosts: def-jam (home server), biggie (desktop), eminem (the Mac, nix-darwin), two install ISOs |
| `.nix/hosts/` | one directory per host; [def-jam's README](.nix/hosts/def-jam/README.md) describes the server |
| `.nix/modules/` | what hosts share: `nixos/`, `darwin/`, `wm/`, and the cross-platform files at the top |
| `.config/`, `.zshrc`, … | linked into `$HOME` by `stow .` from the repository's root; `.stow-local-ignore` lists what isn't |

The apps running on def-jam's k3s cluster are in a separate repository,
[home-ops](https://github.com/eyouga/home-ops). NixOS knows about k3s, never about
the apps.

## Applying

- **The Mac:** `nh darwin switch`; **a NixOS host:** `nh os switch` (nh's flake path is
  set in `.nix/modules/configuration.nix`).
- **def-jam and biggie** also upgrade themselves every night from this repository
  on GitHub (`.nix/modules/nixos/maintenance.nix`): a change that isn't pushed is
  undone by the next upgrade.
- **Stow:** `stow .` from the root. def-jam runs it at every boot.

## Checks

```sh
nix develop ./.nix -c .nix/scripts/ci/all.sh
```

Every linter, and every host evaluated (def-jam built in full where it can be:
x86_64-linux). CI runs it on every push, and so does the pre-push hook (switch it on
once per clone: `git config core.hooksPath .nix/scripts/hooks`).
`.nix/scripts/drv-diff.sh [<base>]` names the hosts a change would rebuild: none, for
a refactor.

[CONTRIBUTING.md](CONTRIBUTING.md) has the rules this repository keeps.
