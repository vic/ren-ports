# Fixture: the gateway's own record is dropped, peers group by remote ASN,
# and a peer in the gateway's AS is refused.
{ ren, ... }:
{
  ren.aspects.flake-terranix-unifi-check-bgp = {
    at = ren.kinds.system;
    checks =
      { system, ... }:
      let
        pkgs = system.legacyPackages;
        inherit (pkgs) lib;
        renderBgpConfig = import ./_unifi-bgp.nix { inherit lib; };
        peer = hostname: ip: asn: { inherit hostname ip asn; };
        args = {
          name = "t";
          cidr = "10.0.0.0/16";
          asn = 65999;
          routerId = "10.0.0.1";
          peers = [
            (peer "s2" "10.0.1.3" 65001)
            (peer "hub" "10.0.1.1" 65000)
            (peer "self" "10.0.0.1" 65000)
            (peer "s1" "10.0.1.2" 65001)
          ];
        };
        rendered = renderBgpConfig args;
        lines = lib.splitString "\n" rendered;
        has = l: builtins.elem l lines;
        ibgp = builtins.tryEval (
          builtins.deepSeq (renderBgpConfig (args // { peers = [ (peer "x" "10.0.1.9" 65999) ]; })) null
        );
        ok =
          has "router bgp 65999"
          && has " bgp router-id 10.0.0.1"
          && has " neighbor as65000 remote-as 65000"
          && has " neighbor as65001 remote-as 65001"
          && has " neighbor 10.0.1.1 peer-group as65000"
          && has " neighbor 10.0.1.2 peer-group as65001"
          && has " neighbor 10.0.1.3 peer-group as65001"
          && has "  neighbor as65001 activate"
          && !(lib.hasInfix "10.0.0.1 peer-group" rendered)
          && lib.length (lib.filter (lib.hasSuffix "peer-group") lines) == 2
          && !ibgp.success;
      in
      {
        unifi-bgp-render =
          assert lib.assertMsg ok "unifi-bgp-render:\n${rendered}";
          pkgs.writeText "unifi-bgp-render" rendered;
      };
  };
}
