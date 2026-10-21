# WORKAROUND for https://github.com/vic/ren/issues/67 (remove this file when includes stop at nested machines):
# an include holds at every descendant scope, so what a host includes also lands on its MicroVM guests.
# Each guest excludes the closure of its host's includes, minus the closure of what the guest wants itself.
# Excluding the leaf aspects works (measured: scratchpad repro leaf-exclude.nix); excluding only the profile does not.
{ ren, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  present = builtins.filter (a: a != null);
  aspect = n: ren.aspects.${n} or null;
  # names of the aspects reachable through `includes` (aspect refs carry `name` and `includes`)
  closure =
    as:
    let
      go =
        seen: todo:
        if todo == [ ] then
          seen
        else
          let
            a = builtins.head todo;
            rest = builtins.tail todo;
          in
          if builtins.elem a.name seen then go seen rest else go (seen ++ [ a.name ]) (rest ++ a.includes);
    in
    go [ ] as;
  isolate =
    name: guest:
    let
      host = guest.on.name;
      wanted = closure (present [
        (aspect name)
        (aspect "${name}-full")
        ren.aspects.microvm-guest
        ren.aspects.profile-base
      ]);
      leaked = closure (present [
        (aspect host)
        (aspect "${host}-full")
      ]);
    in
    {
      at = ren.guest.${name};
      excludes = map (n: ren.aspects.${n}) (lib.subtractLists wanted leaked);
    };
in
{
  ren.aspects = lib.mapAttrs' (name: guest: lib.nameValuePair "${name}-isolate" (isolate name guest)) ren.guest;
}
