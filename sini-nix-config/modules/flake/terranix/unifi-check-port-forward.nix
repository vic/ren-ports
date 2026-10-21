# Fixture: host and cluster records render under their adopt-derived keys,
# another environment's record is dropped, and a shared resource name or
# an overlapping WAN port is refused.
{ ren, ... }:
{
  ren.aspects.flake-terranix-unifi-check-port-forward = {
    at = ren.kinds.system;
    checks =
      { system, ... }:
      let
        pkgs = system.legacyPackages;
        inherit (pkgs) lib;
        inherit (import ./_unifi-lib.nix { inherit lib; }) recordsOf;
        renderPortForwards = import ./_unifi-portfwd.nix { inherit lib recordsOf; };
        inherit (import ./_unifi-check-pf-data.nix) host cluster other;
        render =
          forwards:
          renderPortForwards {
            env = "t";
            wans = [
              "wan"
              "wan2"
            ];
            inherit forwards;
          };
        rendered = render [
          host
          cluster
          other
          (
            host
            // {
              name = "ssh-nat";
              mode = "nat";
              wanPort = "2222";
            }
          )
        ];
        refused = forwards: !(builtins.tryEval (builtins.deepSeq (render forwards) null)).success;
        ok =
          builtins.attrNames rendered == [
            "c1_https_ingress"
            "ssh_to_h1"
          ]
          && rendered.ssh_to_h1 == {
            name = "ssh-to-h1";
            protocol = "tcp";
            wan = {
              interface = "wan";
              port = "22";
            };
            forward = {
              ip = "10.0.0.5";
              port = "22";
            };
          }
          && map (d: d.interface) rendered.c1_https_ingress.destination_ips == [
            "wan"
            "wan2"
          ]
          && rendered.c1_https_ingress.forward.ip == "10.1.0.1"
          && refused [
            host
            (host // { wanPort = "2222"; })
          ]
          && refused [
            cluster
            (host // { wanPort = "8443,443"; })
          ]
          && !refused [
            host
            (
              host
              // {
                name = "dns";
                protocol = "udp";
              }
            )
          ];
      in
      {
        unifi-port-forward-render =
          assert lib.assertMsg ok "unifi-port-forward-render:\n${builtins.toJSON rendered}";
          pkgs.writeText "unifi-port-forward-render" (builtins.toJSON rendered);
      };
  };
}
