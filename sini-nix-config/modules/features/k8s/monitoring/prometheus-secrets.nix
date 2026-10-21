# OIDC client secrets for the prometheus/alertmanager UIs. Same aspect as prometheus.nix.
{ lib, ... }:
let
  uis = [
    "prometheus"
    "alertmanager"
  ];
in
{
  ren.aspects.k8s-monitoring-prometheus.age-secrets =
  { environment, ... }:
  {
    age.secrets = lib.genAttrs (map (ui: "${ui}-oidc-client-secret") uis) (name: {
      rekeyFile = environment.secretPath + "/oidc/${name}.age";
      generator = {
        tags = [ "oidc" ];
        script = "rfc3986-secret";
      };
      sopsOutput = {
        file = "oidc";
        key = lib.removeSuffix "-oidc-client-secret" name;
      };
    });
  };
}
