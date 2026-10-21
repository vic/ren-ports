{ ren, ... }:
{
  ren.aspects.hardware-coolercontrol = {
    nixos =
      { is, host, ... }:
      { pkgs, lib, ... }:
      let
        isLaptop = is ren.aspects.hardware-laptop host;
      in
      {
        environment.systemPackages = lib.optionals (!isLaptop) [ pkgs.liquidctl ];

        programs.coolercontrol.enable = !isLaptop;
      };
  };
}
