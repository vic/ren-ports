# Hosts: NixOS machines and the typed facts aspects key on (den host schema + parametric aspects as data).
{ ren, lib, ... }:
let
  inherit (ren.lib) opt maybe;
  t = lib.types;
  zramT = t.submodule {
    options.algorithm = opt t.str "zstd"; # "lz4" is the faster alternative
    options.memoryPercent = opt t.int 50;
  };
  # zswap is a property of the swapfile: zswap without a swapfile is not representable
  swapfileT = t.submodule {
    options.sizeGiB = opt t.int 32;
    options.path = opt t.str "/var/lib/swapfile";
    options.zswap = opt t.bool false;
  };
  swapT = t.submodule {
    options.zram = maybe zramT;
    options.swapspace = opt t.bool false;
    options.swapfile = maybe swapfileT;
  };
in
{
  ren.kinds.host = {
    below = [ ren.kinds.user ];
    spawns.user = s: ren.helpers.usersOf s.host;
    system = ren.kinds.system;
    users = opt (t.listOf ren.kinds.user) [ ];
    description = t.str; # one line: the README host summary
    longDescription = maybe t.str; # prose under the README entry
    workstation = opt t.bool true; # false: a (headless) server
    signingKey = maybe t.str; # this machine's GPG key that signs commits
    # one CPU power handler; two at once is not representable (den asserted it)
    cpuPower = opt (t.nullOr (t.enum [ "auto-cpufreq" "watt" ])) "auto-cpufreq";
    swap = opt swapT { };
    ttyAutologin = maybe ren.kinds.user; # getty@tty1 logs this user in
    vmAutologin = maybe ren.kinds.user; # same, only in `nixos-rebuild build-vm`
  };
}
