# systems and variants: per-system nixpkgs and flake outputs; the full and the minimal (bootstrap) build of each machine.
{
  ren,
  lib,
  inputs,
  ...
}:
let
  t = lib.types;
  ofFleet = s: lib.filterAttrs (_: m: ren.lib.same m.fleet s.fleet);
  # the old flake output `pkgs.<system>`: nixpkgs with the repository overlays
  pkgsFor =
    system:
    import inputs.nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          # matrix
          "olm-3.2.16"
        ];
      };
      overlays = map (n: ren.helpers.overlays.${n}) [
        "default"
        "stables"
        "modifications"
      ];
    };
in
{
  ren.kinds.system.legacyPackages = t.raw;
  ren.system = inputs.nixpkgs.lib.genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ] (system: { legacyPackages = pkgsFor system; });

  # `minimal` was a specialArg; here each machine has one scope per variant
  ren.kinds.variant = {
    below = [
      ren.kinds.host
      ren.kinds.mac
      ren.kinds.home
      ren.kinds.droid
    ];
    # standalone homes and phones had no minimal build
    # machines spawn in their own fleet
    spawns.host = s: if s.variant.minimal && s.fleet.name != "swarsel" then { } else ofFleet s ren.host; # the sandbox has no minimal build
    spawns.mac = s: ofFleet s ren.mac;
    spawns.home = s: if s.variant.minimal then { } else ofFleet s ren.home;
    spawns.droid = s: if s.variant.minimal then { } else ofFleet s ren.droid;
    minimal = t.bool;
  };
  ren.variant.full.minimal = false;
  ren.variant.minimal.minimal = true;
}
