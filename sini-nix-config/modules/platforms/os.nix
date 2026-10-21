# os class: OS config an aspect brings to its machine, forwarded into nixos (hosts) or darwin (macs).
# User-scope content forwards up to its machine (Ren classes.nix: a class's own name forwards to the nearest ancestor branch).
{ ren, ... }:
let
  inherit (ren.lib) and anyOf within;
in
{
  ren.classes.os = [
    {
      at = ren.kinds.host;
      into = _: ms: { nixos.imports = ms; };
    }
    {
      at = ren.kinds.mac;
      into = _: ms: { darwin.imports = ms; };
    }
    # droids: nix-on-droid takes os content too (nixpkgs-overlays channel targets the nearest machine)
    {
      at = ren.kinds.droid;
      into = _: ms: { droid.imports = ms; };
    }
    {
      at = and [
        ren.kinds.user
        (anyOf [
          (within ren.kinds.host)
          (within ren.kinds.mac)
        ])
      ];
      into = _: ms: { os.imports = ms; };
    }
  ];
}
