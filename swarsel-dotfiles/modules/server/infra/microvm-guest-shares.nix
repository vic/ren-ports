{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.microvm-guest-shares.nixos =
    {
      config,
      lib,
      guest,
      ...
    }:
    {
      config.microvm.shares = [
        {
          mountPoint = "/persist";
          proto = "virtiofs";
          source = "${
            lib.optionalString guest.on.isImpermanence "/persist"
          }/microvms/${config.networking.hostName}";
          tag = "persist";
        }
      ];
    }

  ;
}
