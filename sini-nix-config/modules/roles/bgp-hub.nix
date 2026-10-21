{ ren, ... }:
{
  ren.aspects.bgp-hub = {
    includes = with ren.aspects; [
      svc-bgp-hub
    ];
  };
}
