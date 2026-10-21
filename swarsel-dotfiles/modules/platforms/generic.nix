# generic: content for every module system (old flake.modules.generic); each branch forwards where it lands.
{ ren, ... }:
{
  ren.classes.generic = [
    {
      at = ren.kinds.host; # hosts and guests
      into = _: ms: { nixos.imports = ms; };
    }
    {
      at = ren.kinds.mac;
      into = _: ms: { darwin.imports = ms; };
    }
    {
      at = ren.kinds.user;
      into = _: ms: { homeManager.imports = ms; };
    }
  ];
}
