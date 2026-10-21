# genie-guard's manifests, as a pure function so genie-guard-check can run it
# with the flag forced on and stand-in secrets (a Ren aspect cannot be called).
{ ren, lib }:
{
  config,
  cluster,
  images,
  xmsg-nodes ? [ ],
}:
let
  sh = import ./_genie-guard-shared.nix;
  inherit (sh) namespace name uid;
  g = import ./_genie-guard-hubs.nix { inherit ren lib; } { inherit cluster xmsg-nodes; };

  # Enabled, and refused by name until the guard image is pinned.
  enabled =
    if g.cfg.enable && !(images ? "sini/genie-guard") then
      throw ''
        genie-guard: images/sini/genie-guard/default.nix is absent. Publish ghcr.io/sini/genie-guard,
        then run `nix run .#oci-image-updater -- init --image-name ghcr.io/sini/genie-guard ...`
        and move the file to images/sini/genie-guard/.
      ''
    else
      g.cfg.enable;
in
lib.optionalAttrs enabled {
  applications.${name} = {
    inherit namespace;

    resources = {
      serviceAccounts.${name}.automountServiceAccountToken = false;

      certificates.${name}.spec = import ./_genie-guard-cert.nix;

      configMaps."${name}-xmsg-peers".data."peers.json" = builtins.toJSON g.peers;

      # The URL is no secret, but it rides in the same Secret so the guard's
      # whole configuration is one object.
      secrets.${name}.stringData = {
        api-key = config.age.secrets.genie-guard-api-key.sopsRef;
        # The hub's own guard setting, so both guards ask the same endpoint.
        ninfer-url = g.hub.dev-ai-mcp-xmsg.genieGuard.ninferUrl;
      };

      deployments.${name}.spec = {
        replicas = 1;
        selector.matchLabels."app.kubernetes.io/name" = name;
        template = {
          metadata.labels."app.kubernetes.io/name" = name;
          spec = {
            serviceAccountName = name;
            automountServiceAccountToken = false;
            enableServiceLinks = false;
            securityContext = {
              runAsUser = uid;
              runAsGroup = uid;
              runAsNonRoot = true;
              fsGroup = uid;
              seccompProfile.type = "RuntimeDefault";
            };
            containers = import ./_genie-guard-containers.nix { inherit images; };
            volumes = import ./_genie-guard-volumes.nix;
          };
        };
      };

      ciliumClusterwideNetworkPolicies."allow-xmsg-egress-${namespace}-${name}".spec = import ./_genie-guard-egress.nix g.egressTargets;
    };
  };
}
