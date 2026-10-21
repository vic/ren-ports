{ ... }:
{
  ren.aspects.app-security-proton-vpn.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.proton-vpn ];
    };
}
