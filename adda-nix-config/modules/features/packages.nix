# Packages: a system scope emits flake packages; content reads them back with `addax.selfPackages pkgs`.
{ ren, ... }:
{
  ren.channels.packages = {
    fold = ren.lib.fold.attrs;
    at = ren.kinds.system;
    to = e: e;
    into = { system, ... }: p: { packages.${system.name} = p; };
  };
}
