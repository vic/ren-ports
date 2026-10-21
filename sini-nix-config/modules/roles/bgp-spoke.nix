{ ren, ... }:
{
  ren.aspects.bgp-spoke = {
    includes = with ren.aspects; [
      svc-bgp-spoke
    ];
  };
}
