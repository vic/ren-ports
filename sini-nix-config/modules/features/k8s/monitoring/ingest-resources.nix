# monitoring-ingest Secret + Certificate + ingress CNP. Same aspect as ingest.nix.
{ ren, ... }:
let
  name = "monitoring-ingest";
  toPorts = [
    {
      ports = [
        {
          port = "8443";
          protocol = "TCP";
        }
      ];
    }
  ];
in
{
  ren.aspects.k8s-monitoring-ingest.k8s-manifests =
    { config, environment, ... }:
    let
      hostname = "ingest.${environment.domain}";
    in
    {
      applications.${name}.resources = {
        secrets."${name}-htpasswd".stringData.htpasswd =
          config.age.secrets.monitoring-ingest-htpasswd.sopsRef;

        certificates.${name}.spec = {
          secretName = "${name}-tls";
          issuerRef = {
            name = "${ren.helpers.resourceForDomain hostname}-issuer";
            kind = "ClusterIssuer";
          };
          dnsNames = [ hostname ];
        };

        ciliumNetworkPolicies.allow-ingest-from-lan.spec = {
          description = "Allow the cluster nodes and LAN hosts to push to the monitoring ingest proxy.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = name;
          ingress = [
            # The k3s nodes' own Alloy: cluster nodes are host / remote-node
            # identities to Cilium, never CIDR matches.
            {
              fromEntities = [
                "host"
                "remote-node"
              ];
              inherit toPorts;
            }
            {
              fromCIDR = [
                "10.0.0.0/8"
                "100.64.0.0/10"
              ];
              inherit toPorts;
            }
          ];
        };
      };
    };
}
