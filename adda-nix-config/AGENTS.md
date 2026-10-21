# AGENTS.md

Guidance for coding agents (Claude Code, omp, etc.) working in this repository.

## What this is

Adda's NixOS fleet, written in Ren. Five hosts: `fulgur-nixos`, `mensa-nixos`, `nomen-nixos`,
`fabrica-nixos`, `harena-nixos` (one dir each in `modules/hosts/`). Two users: `adda` (personal)
and `ichocholaty` (work identity on `fabrica-nixos` and `harena-nixos`).

`import-tree` loads every `.nix` file under `modules/`. Paths containing `/_` are skipped. There is
no import list. A new `.nix` file under `modules/` takes effect if it is a valid module. Directory
names are for humans only. Ren does not read them.

## Layout

| dir | role |
| --- | --- |
| `modules/topology/` | The kinds: fleet, system, host, user. Typed facts live here. |
| `modules/platforms/` | Classes that build systems: nixos, os, account, homeManager, aliases. |
| `modules/features/` | Defaults every host or user gets: base, network, packages, state version. |
| `modules/hosts/` | One dir per host: the `ren.host` instance, its aspect, `_hardware.nix`. |
| `modules/people/` | The users: `adda/` and `ichocholaty.nix`. |
| `modules/flake/` | Flake outputs: channels, flake-file, files class, devshell, formatter, tests, templates. |
| `modules/docs/` | README generator, fleet graphs, vocabulary. |
| `modules/helpers.nix` | `ren.helpers`: pure functions shared by all files, bound as `addax`. |

Capability dirs hold aspects: `ai`, `audio`, `console`, `desktop`, `development`, `editors`,
`filesystems`, `hardware`, `kernel`, `languages`, `media`, `misc`, `network`, `security`,
`services`, `swap`, `virtualisation`, `work-vm`.

## Ren model in this repo

- **Kinds** are typed records: `fleet`, `system`, `host`, `user` (`modules/topology/`). Aspects read
  their facts. Aspects do not read each other. One fleet, `addax`, owns the tailnet.
- **Instances**: `ren.host.<name>` (see `modules/hosts/fulgur-nixos/fulgur-nixos.nix`) and
  `ren.user.<name>`. A host lists its `users` inline.
- **Aspects** are `ren.aspects.<name>`. `at = ren.host.<name>` places the aspect on an instance.
  `includes = [ ... ]` pulls in other aspects. A host or user has a feature when it includes it.
  Aspect names are flat and hyphenated, e.g. `audio-pipewire`, `kernel-xanmod`.
- **Class keys** inside an aspect route content: `nixos` (NixOS module), `os` (host NixOS config
  from a user aspect), `account` (`users.users.<login>`), `homeManager` (home of a user inside the
  host), `aliases` / `abbreviations` (shell aliases, written into home-manager). Editor classes
  (`helixSettings`, `zedSettings`, `vscodiumSettings`, ...) are in `modules/editors/quirks.nix`.
  Classes are defined in `modules/platforms/`.
- **Channels** (`ren.channels.<name>`) move data between scopes: `flake-inputs`, `overlays`,
  `service-domains`, `vscodium-extensions`, `zed-extensions`, `packages`, `apps`, `checks`,
  `devshells`, `formatter`, `templates`. Defined in `modules/flake/channels.nix`,
  `modules/flake/flake-file.nix` and next to their users.
- **Helpers**: `addax = ren.helpers;` in each file that needs them.

## Generated files: do not hand-edit

`flake.nix`, `README.md`, `.envrc`, `.gitignore` start with a DO-NOT-EDIT comment.

- `flake.nix`: written from the `flake-inputs` channel by the `flake-file` class
  (`modules/flake/flake-file.nix`).
- `README.md`: generated from `modules/docs/`.
- `.envrc`, `.gitignore`: declared in `modules/flake/files/`.

Edit the Nix source, then run `just generate`.

## How to evolve

**Add a host.** Create `modules/hosts/<name>/<name>.nix` with `ren.host.<name>` (`system`, `users`,
`description`, other topology fields) and `ren.aspects.<name>` with `at = ren.host.<name>` and
`includes`. Put hardware in `_hardware.nix` and import it through `nixos.imports`. Copy
`modules/hosts/fulgur-nixos/fulgur-nixos.nix`. Add the age key to `.sops.yaml`, run
`just sops-update`.

**Add a user.** Create `modules/people/<name>.nix` with a `ren.user.<name>` and its aspect (see
`modules/people/ichocholaty.nix`). Reference it from a host `users` list. Class keys carry content.

**Add a feature.** Add `ren.aspects.<dir>-<name>` in the matching capability dir. Include it from
the host or user aspect that wants it. Make it reusable even if one host uses it. Keep
`modules/features/` minimal: only what a bare headless machine wants. Audio, fonts, firmware,
NetworkManager, non-default kernels and the graphical session are opt-in aspects. A feature that
needs editor settings emits them through the editor classes and channels.

**Add a flake input.** Name it through the `flake-inputs` channel from the scope that needs it.
Run `just generate`. Never edit `flake.nix` by hand. Existing inputs include `denful/flake-file`
and `denful/import-tree`.

**Add per-host data.** Add a typed option to the kind in `modules/topology/`. Make invalid states
unrepresentable:

- `swap` is a record `zram`, `swapspace`, `swapfile`. `zswap` is a field of `swapfile`, so zswap
  without a swapfile does not exist.
- `cpuPower` is an enum: `auto-cpufreq` or `watt`. A host picks one.
- `ttyAutologin` and `vmAutologin` hold a user, not a string.

**Rules.**

- No `_module.args`. Use options, channels or `ren.helpers`.
- No nested `let`. Avoid `with`.
- Keep files under 100 lines. Split by concern.
- A file's name matches its path and aspect name.
- Use helpers through `addax`. Add shared pure functions to `modules/helpers.nix`.
- Typed options over assertions. Prefer an enum or submodule to a string checked at runtime.

## Commands

[`just`](https://github.com/casey/just) is the runner (shell: `nu`). `just --list` / `just help`
shows recipes.

- `just` / `just switch` (`s`): `nh os switch`. `just build` (`bd`), `just test` (`t`),
  `just boot` (`b`): build only, activate for this boot, set boot default.
- `just check` / `just c`: `nix flake check`. `just fmt` / `just f`: `nix fmt`.
- `just generate` / `just g`: `nix run .#generate-files`. Regenerates the generated files.
- `just update` (`u`): `nix flake update`. `just system-update` (`su`): generate, update, switch.
- `just repl` (`r`), `just generations` (`ge`), `just sops-update [FILE]` (`sou`).
- `host.just`: `just host::switch HOST=...`, `host::build`, `host::boot` for another host.
- Trailing flags pass to the command on single-command recipes (`just switch --no-nom`). Each such
  recipe needs `*ARGS` in the signature and `{{ARGS}}` in the body. Multi-dependency recipes
  (`system-update`, `update`) cannot forward flags. Name the recipe: `just -- --no-nom` fails.
- Evaluate one host without building:
  `nix eval --extra-experimental-features pipe-operators --raw "path:$PWD#nixosConfigurations.<h>.config.system.build.toplevel.drvPath"`
- Tests: `nix flake check`. Checks are in `modules/flake/tests.nix`. No other test suite.

Formatting is `treefmt` (`modules/flake/formatter.nix`): `nixfmt`, `deadnix`, `statix`
(`statix.toml`), `pedantix`, `shellcheck`, `ruff`, `taplo`, `toml-sort`, `mdformat`. Run `nix fmt`,
not the formatters directly.

## Secrets

Secrets use [sops-nix](https://github.com/Mic92/sops-nix) (`modules/security/sops.nix`,
`.sops.yaml`) in `secrets/*.{yaml,json,env,ini}`, keyed per host and user with `age` keys. Never
write plaintext secrets into tracked files. Edit with `sops secrets/<file>`. Re-key with
`just sops-update` after adding a host or user key.

## Infrastructure as code (OpenTofu via Tofunix)

The tailnet state (Tailscale ACLs, DNS, key expiry in `terraform/tailscale/`) is generated from Nix
with [Tofunix](https://gitlab.com/TECHNOFAB/tofunix). `terraform/tailscale/config.nix` is the
tofunix module. Attribute names mirror HCL. Typos fail `nix build`, not `tofu plan`.
`modules/flake/tofunix.nix` wires it to `packages.tofunix`, a wrapped `opentofu` with Nix plugins
(no `tofu init`).

- Tofunix comes from omniflake as `omniflake.unified.tofunix-technofab11`. The owner suffix is
  needed: the bare `tofunix` entry is another project.
- Run `just tofu <plan|apply|validate|...>` (alias `tf`). Flags pass through. The wrapper enters
  `terraform/tailscale/` and exports `secrets/tailscale-terraform.env` via sops if direnv has not.
- `ref.var.<name>` and `ref.resource.<type>.<name>.<attr>` build `${...}` strings, only for
  attributes set in the module. For computed attributes write the string out:
  `"\${data.tailscale_device.mensa_nixos.node_id}"`.
- Inspect the config: `nix build .#tofunix.tfjson` gives `main.tf.json`.
- Never add `*.tf` files to `terraform/tailscale/`. The store path is the only config source.

## Version control

The repo is git with a colocated [Jujutsu (`jj`)](https://github.com/jj-vcs/jj) repo. `jj` is the
preferred VCS (config in `modules/console/vcs/jujutsu.nix`; the `jj` wrapper opens `jjui` with no
arguments). `git.private-commits` keeps `wip:`/`WIP`/`private:`/`todo:`/`TODO` commits from being
pushed. History uses `+wip` / `+WIP` on work-in-progress subjects.

Commit subjects: `<scope>: +<type> <Description>`, e.g. `fish: +feat Add fuzzy command builder
(ctrl-g)`, `treewide: +fmt Format the code`. `<scope>` is the aspect or program touched. `<type>` is
one of `feat`, `fix`, `refactor`, `chore`, `fmt`, `wip`.
