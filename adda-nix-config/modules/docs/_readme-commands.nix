# readme commands: the nix and just entry points of this repo (justfile, flake.just, host.just).
''
  ## Commands

  ```sh
  nix build .#nixosConfigurations.fulgur-nixos.config.system.build.toplevel
  nix run .#write-files     # regenerate this README (and the other generated files)
  nix run .#write-flake     # regenerate flake.nix from the flake-inputs channel
  nix run .#generate-files  # both of the above
  nix flake check           # includes checks.x86_64-linux."files/README.md"
  ```

  `just` runs recipes through Nushell. Trailing flags go to the underlying command.

  | recipe | runs |
  | --- | --- |
  | `just` / `just switch` (`s`) | `nh os switch` for this host |
  | `just build` (`bd`), `boot` (`b`), `test` (`t`) | `nh os build`, `boot`, `test` |
  | `just host::switch <host>`, `host::build`, `host::boot` | the same for another host (`--hostname`; switch and boot use `--target-host`) |
  | `just fmt` (`f`) | `nix fmt` (treefmt) |
  | `just generate` (`g`) | `nix run .#generate-files` |
  | `just check` (`c`) | `nix flake check` |
  | `just flake::update`, `flake::show` | `nix flake update`, `nix flake show` |
  | `just system-update` (`su`) | `generate`, then `flake::update`, then `switch` |
  | `just tofu` (`tf`) | `nix run .#tofunix`, OpenTofu for the tailnet |
  | `just sops-update` (`sou`) | `sops updatekeys --yes` |
  | `just generations` (`ge`), `repl` (`r`) | `nh os info`, `nh os repl` |
''
