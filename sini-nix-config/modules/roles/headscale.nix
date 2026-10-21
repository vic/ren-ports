{ ren, ... }:
{
  ren.aspects.headscale = {
    includes = with ren.aspects; [
      svc-networking-headscale
    ];
  };
}
