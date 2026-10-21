# channels: flake outputs an aspect emits (apps, checks, devshells, formatter, templates); `packages` is features/packages.nix.
{ ren, ... }:
let
  # a system scope emits `{ name = value; }`, written once per system as `<output>.<system>`
  atSystem = {
    fold = ren.lib.fold.attrs;
    at = ren.kinds.system;
    to = e: e;
  };
in
{
  ren.channels.apps = atSystem // {
    into = { system, ... }: a: { apps.${system.name} = a; };
  };

  ren.channels.devshells = atSystem // {
    into = { system, ... }: s: { devShells.${system.name} = s; };
  };

  ren.channels.formatter = atSystem // {
    into = { system, ... }: f: { formatter.${system.name} = f.treefmt; };
  };

  # any scope emits flake checks as { <system>.<name> = drv; }; the fleet writes `checks` once
  ren.channels.checks = {
    fold = ren.lib.fold.attrs;
    to = _: ren.kinds.fleet;
    into = { ... }: checks: { inherit checks; };
  };

  # top-level flake output `templates`
  ren.channels.templates = {
    fold = ren.lib.fold.attrs;
    to = _: ren.kinds.fleet;
    into = { ... }: templates: { inherit templates; };
  };
}
