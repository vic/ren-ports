# compat: default.nix and shell.nix shims so `nix-build` / `nix-shell` work on this flake.
{ ren, ... }:
let
  # `nix-build` / `nix-shell` can't read `flake.nix` themselves, so both shims re-enter this flake through
  #  `builtins.getFlake`, which reuses nix's own (locked) flake evaluation.
  #
  # Deliberately *not* flake-compat: it re-fetches every lock node itself, so duplicated lock nodes
  #  end up as distinct trees and the module system dies with duplicate declarations.
  #  `getFlake` shares nix's node deduplication and evaluates exactly like `nix develop`.
  #
  # `toString ./.` (not `self`) keeps the shims callable as plain `nix-shell` / `nix-build` with no `--arg`.
  getFlake = "builtins.getFlake (toString ./.)";
in
{
  ren.aspects.files-compat = {
    at = ren.system.x86_64-linux;
    files =
      { config, ... }:
      {
        files.file."default.nix" = {
          format = config.files.warning.format;
          # A bare attrset, not a function: statix rewrites an ignored `{ ... }:` pattern to `_:`, which
          #  `nix-build`'s auto-call refuses, breaking `nix-build -A <output>`.
          text = "${getFlake}\n";
        };

        files.file."shell.nix" = {
          format = config.files.warning.format;
          text = ''
            { system ? builtins.currentSystem }:
            (${getFlake}).devShells.''${system}.default
          '';
        };
      };
  };
}
