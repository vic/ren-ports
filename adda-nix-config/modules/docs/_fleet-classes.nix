# fleet classes (part of docs/_fleet-ir.nix): static class forwarding; `live` edges carry instance names read from Ren.
{
  ren,
  id,
  uniq,
  hosts,
}:
let
  inherit (builtins)
    attrNames
    concatMap
    concatStringsSep
    elem
    filter
    throw
    ;
  e = live: from: to: label: {
    inherit
      live
      from
      to
      label
      ;
  };
  fwd = [
    (e false "os" "nixos" "")
    (e false "account" "nixos" "users.users")
    (e false "homeManager" "nixos" "home-manager.users")
    (e false "aliases" "homeManager" "")
    (e false "abbreviations" "homeManager" "")
    (e false "helixSettings" "homeManager" "")
    (e false "helixLanguages" "homeManager" "")
    (e false "helixPackages" "homeManager" "")
    (e false "zedSettings" "homeManager" "")
    (e false "zedPackages" "homeManager" "")
    (e false "vscodiumSettings" "homeManager" "")
    (e true "nixos" "nixosConfigurations" (concatStringsSep ", " (map (h: h.name) hosts)))
    (e false "files" "packages" "write-files")
    (e false "files" "checks" "files/README.md")
    (e false "flake-file" "packages" "write-flake")
    (e false "flake-file" "checks" "flake-file")
  ];
  froms = map (x: x.from) fwd;
  # every live class is drawn, every drawn source is a live class
  bad =
    filter (c: !(elem c froms)) (attrNames ren.classes) ++ filter (c: !(ren.classes ? ${c})) froms;
  node = s: {
    id = id s;
    label = s;
    kind = if ren.classes ? ${s} then "class" else "output";
    group = null;
  };
in
if bad == [ ] then
  {
    nodes = uniq (
      concatMap (x: [
        (node x.from)
        (node x.to)
      ]) fwd
    );
    edges = map (
      x:
      x
      // {
        from = id x.from;
        to = id x.to;
      }
    ) fwd;
  }
else
  throw "docs/_fleet-classes.nix: unknown or undrawn classes [${toString bad}]"
