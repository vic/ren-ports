# Gen schema types for nixpkgs-only kind field types (port, ints.*, strMatching): `types.refined` with the
# same bounds/regex (gen-types lib/refined.nix:90). Fleet `lib` is ren.genLib, which has no such types.
{ ren, lib, ... }:
let
  t = lib.types;
  between = lo: hi: t.refined t.int {
    check = n: n >= lo && n <= hi;
    message = "between ${toString lo} and ${toString hi}";
  };
in
{
  ren.helpers.types = {
    inherit between;
    port = between 0 65535;
    positive = t.refined t.int { check = n: n > 0; message = "positive"; };
    unsigned = t.refined t.int { check = n: n >= 0; message = "unsigned"; };
    match = re: t.refined t.str { check = s: builtins.match re s != null; message = "matching ${re}"; };
  };
}
