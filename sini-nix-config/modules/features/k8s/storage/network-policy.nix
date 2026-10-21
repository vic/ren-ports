# Garage namespace CiliumNetworkPolicies: default-deny, every flow enumerated, no world egress.
{ ... }:
let
  garage.matchLabels."app.kubernetes.io/name" = "garage";
  ns = name: { matchLabels."k8s:io.kubernetes.pod.namespace" = name; };
  toPorts = ports: [
    {
      ports = map (port: {
        inherit port;
        protocol = "TCP";
      }) ports;
    }
  ];
in
{
  ren.aspects.k8s-storage-garage-network-policy.k8s-manifests = {
    applications.garage.resources.ciliumNetworkPolicies = {
      # RPC mesh: Garage pods talk to each other on 3901 (ingress + egress).
      allow-garage-rpc-mesh.spec = {
        description = "Garage inter-node RPC mesh (3901) within the garage namespace.";
        endpointSelector = garage;
        ingress = [
          {
            fromEndpoints = [ garage ];
            toPorts = toPorts [ "3901" ];
          }
        ];
        egress = [
          {
            toEndpoints = [ garage ];
            toPorts = toPorts [ "3901" ];
          }
        ];
      };
      # Website endpoint (3902) for static sites, from the gateways only.
      allow-garage-web-ingress.spec = {
        description = "Garage web (3902) ingress from gateways (static sites).";
        endpointSelector = garage;
        ingress = [
          {
            fromEndpoints = [ (ns "gateways") ];
            toPorts = toPorts [ "3902" ];
          }
        ];
      };

      # S3 ingress on 3900 from the gateways namespace (public route backend)
      # and in-cluster consumer namespaces (burrito).
      allow-garage-s3-ingress.spec = {
        description = "S3 API (3900) ingress from gateways + consumer namespaces.";
        endpointSelector = garage;
        ingress = [
          {
            fromEndpoints = [
              (ns "gateways")
              (ns "burrito")
            ];
            toPorts = toPorts [ "3900" ];
          }
        ];
      };

      # Admin API (3903) ingress from within the garage namespace: the operator
      # polls each node's admin API (GetClusterStatus) to discover node IDs,
      # connect peers and drive layout - without this the cluster never forms
      # ("Layout not ready"). garage-ui also uses it. The admin API is
      # admin-token-gated, so namespace-scoping is safe.
      allow-garage-admin-ingress.spec = {
        description = "Admin API (3903) ingress from the garage namespace (operator + UI).";
        endpointSelector = garage;
        ingress = [
          {
            fromEndpoints = [ (ns "garage") ];
            toPorts = toPorts [ "3903" ];
          }
        ];
      };

      # kube-apiserver egress: Garage k8s peer discovery + operator CR
      # reconciliation (toEntities, NOT world - the coder-pg precedent).
      allow-garage-apiserver-egress = {
        metadata.annotations."argocd.argoproj.io/sync-wave" = "-1";
        spec = {
          description = "garage-ns pods (Garage + operator) to kube-apiserver.";
          endpointSelector = ns "garage";
          egress = [
            {
              toEntities = [ "kube-apiserver" ];
              toPorts = toPorts [
                "443"
                "6443"
              ];
            }
          ];
        };
      };
    };
  };
}
