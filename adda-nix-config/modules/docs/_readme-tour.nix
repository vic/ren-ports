# readme tour: each Ren keyword once, linked to the line in adda that uses it.
let
  lines =
    file:
    builtins.filter builtins.isString (builtins.split "\n" (builtins.readFile (../. + "/${file}")));
  has = needle: l: builtins.replaceStrings [ needle ] [ "" ] l != l; # literal substring, no regex
  hits =
    needle: ls:
    builtins.filter (i: has needle (builtins.elemAt ls i)) (
      builtins.genList (i: i) (builtins.length ls)
    );
  # `src file needle text`: a link to the first line of modules/<file> that contains needle.
  # The line is found at eval time, so links follow edits; a needle that is gone is an eval error.
  src =
    file: needle: text:
    if hits needle (lines file) == [ ] then
      throw "docs/_readme-tour.nix: `${needle}` not found in modules/${file}"
    else
      "[`${text}`](modules/${file}#L${toString (builtins.head (hits needle (lines file)) + 1)})";
in
''
  ## A tour

  | Ren | in adda |
  | --- | --- |
  | `ren.kinds.<k>` | typed data: ${src "topology/fleet.nix" "ren.kinds.fleet = {" "fleet"}, ${
    src "topology/host.nix" "ren.kinds.host = {" "host"
  }, ${src "topology/user.nix" "ren.kinds.user = {" "user"} |
  | `ren.<k>.<name>` | an instance: ${
    src "hosts/mensa-nixos/mensa-nixos.nix" "ren.host.mensa-nixos = {" "ren.host.mensa-nixos"
  }, ${src "people/adda/adda.nix" "ren.user.adda = {" "ren.user.adda"}, ${
    src "topology/fleet.nix" "ren.fleet.addax" "ren.fleet.addax"
  } |
  | `below`, `spawns` | the scope tree: ${
    src "topology/fleet.nix" "below = [" "fleet → system, host"
  }, ${src "topology/host.nix" "below = [ ren.kinds.user ]" "host → user"}, ${
    src "topology/host.nix" "spawns.user" "a host spawns a scope per user"
  } |
  | `ren.aspects.<a>` | one feature: ${
    src "hosts/mensa-nixos/mensa-nixos.nix" "ren.aspects.mensa-nixos = {" "mensa-nixos"
  }, ${src "swap/swap.nix" "ren.aspects.zram = {" "zram"}, ${
    src "hardware/cpu-power.nix" "ren.aspects.watt = {" "watt"
  } |
  | `at` | where an aspect is on: ${
    src "people/ichocholaty.nix" "at = ren.user.ichocholaty" "at = ren.user.ichocholaty"
  }, ${
    src "swap/swap.nix" "at = on (s: s.host.swap.zram" "zram only where the host has a zram swap"
  } |
  | `includes` | add aspects below a scope: ${
    src "people/ichocholaty.nix" "includes = [ ren.aspects.workVM-user ]"
      "the work user includes workVM-user"
  } |
  | `ren.classes.<c>` | a module system an aspect key feeds: ${
    src "platforms/nixos.nix" "ren.classes.nixos = {" "nixos"
  }, ${src "platforms/nixos.nix" "ren.classes.os = {" "os"}, ${
    src "platforms/nixos.nix" "ren.classes.account = {" "account"
  }, ${src "platforms/home-manager.nix" "ren.classes.homeManager = {" "homeManager"} |
  | `into` | how a class builds: ${
    src "platforms/nixos.nix" "nixosConfigurations.$" "nixosConfigurations.<host>"
  }, ${src "flake/files/files.nix" "packages.write-files" "files → write-files"} |
  | `ren.channels.<c>` | data a feature emits for a receiver: ${
    src "features/base/overlays.nix" "ren.channels.overlays" "overlays"
  }, ${src "services/caddy.nix" "ren.channels.service-domains" "service-domains"}, ${
    src "flake/flake-file.nix" "ren.channels.flake-inputs" "flake-inputs"
  } |
  | `fold`, `to` | how a channel merges, and who reads it: ${
    src "features/base/overlays.nix" "fold = ren.lib.fold.list" "overlays fold into a list"
  }, ${src "features/base/overlays.nix" "to = e: ren.lib.upTo" "received at the host"} |
  | `and`, `within`, `has`, `when` | predicates for `at`: ${
    src "hardware/cpu-power.nix" "ren.lib.when (s: s.host.cpuPower" "when (s: s.host.cpuPower == n)"
  }, ${src "platforms/home-manager.nix" "(within ren.kinds.host)" "a user within a host"} |
  | `ren.helpers` | pure functions shared by content: ${
    src "platforms/home-manager.nix" "ren.helpers.intoHm = intoHm" "intoHm"
  } |
''
