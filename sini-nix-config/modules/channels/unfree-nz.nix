# channels n-z (unfree): package names allowed under allowUnfree (emit a name or a list); any -> nearest machine (R:578).
{ ren, ... }:
{
  ren.channels.unfree = {
    fold = ren.lib.fold.set;
    to = e: ren.lib.upTo ren.kinds.machine e;
    into =
      { lib, ... }:
      names: {
        os.nixpkgs.config.allowUnfreePredicate = p: builtins.elem (lib.getName p) (lib.flatten names);
      };
  };
}
