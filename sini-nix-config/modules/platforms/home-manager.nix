# homeManager class (users on hosts, macs, droids), homeLinux/homeDarwin sub-classes, hm module glue on machines with users.
{ ren, ... }:
let
  inherit (ren.lib)
    and
    within
    has
    when
    ;
  user = ren.kinds.user;
  inPlace = _: ms: { homeManager.imports = ms; }; # sub-class forwarded in place
  sysOf = s: (s.host or s.mac or s.droid).system.name;
  onSuffix = re: and [ user (when (s: builtins.match re (sysOf s) != null)) ];
in
{
  ren.classes.homeManager = [
    {
      at = and [ user (within ren.kinds.host) ];
      into = { user, ... }: ms: { nixos.home-manager.users.${user.name}.imports = ms; };
    }
    {
      at = and [ user (within ren.kinds.mac) ];
      into = { user, ... }: ms: { darwin.home-manager.users.${user.name}.imports = ms; };
    }
    {
      at = and [ user (within ren.kinds.droid) ];
      # nix-on-droid has a single home-manager.config
      into = _: ms: { droid.home-manager.config.imports = ms; };
    }
  ];
  ren.classes.homeLinux = {
    at = onSuffix ".*-linux";
    into = inPlace;
  };
  ren.classes.homeDarwin = {
    at = onSuffix ".*-darwin";
    into = inPlace;
  };
  # homeAarch64 dropped (0 uses)

  ren.aspects.hm-nixos = {
    at = and [ ren.kinds.host (has user) ];
    nixos = { host, ... }: { imports = [ host.channel.home-manager.nixosModules.home-manager ]; };
  };
  ren.aspects.hm-darwin = {
    at = and [ ren.kinds.mac (has user) ];
    darwin = { mac, ... }: { imports = [ mac.channel.home-manager.darwinModules.home-manager ]; };
  };
  # hm battery config (useGlobalPkgs, useUserPackages, backupFileExtension, extraSpecialArgs) is aspect users-home-manager-shared (features/users/home-manager-shared.nix).
  # The droid hm module is provided by nix-on-droid itself.
}
