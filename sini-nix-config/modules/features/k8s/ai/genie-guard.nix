# genie-guard as a pod: an xmsg leaf (xmsg X19, federation plan §2.1) whose hub is
# the system owner's xmsg on bitstream. Senders on the hub address it as
# `genie-guard@genie-guard.genie` (its node name derives from its URI SAN,
# `<sa>.<ns>`); the hub queues those sends in the leaf's mailbox,
# and the leaf container long-polls it over mTLS and hands each message to the
# guard on register.sock. Nothing connects in: no Service, no ingress.
#
# Both containers run as one uid, because the leaf admits a registration on
# register.sock by SO_PEERCRED uid (exe attestation is impossible across
# containers). XDG_RUNTIME_DIR is an emptyDir mounted in both; the leaf creates
# its `xmsg/` socket dir under it, owned by that uid and mode 0700, as xmsg
# requires of an existing socket dir (an emptyDir root is owned by root).
#
# Identity (plan §6.7): a cert-manager Certificate from xmsg-cluster-ca whose one
# URI SAN is spiffe://json64.dev/ns/genie/sa/genie-guard. Its Secret's tls.crt is
# leaf, cluster intermediate and root (xmsg-ca.nix), which is the chain
# --fed-cert presents; its ca.crt is the root, the trust anchor for the hub. xmsg
# reloads both when cert-manager rotates them (X17).
#
# Egress (plan §6.4): the hub's federation port only, and the model ports through
# model-egress.nix, both granted to this namespace and service account. The hub
# is addressed by its LAN IP, so no DNS: xmsg's CA verifier checks the chain and
# the URI SAN, never a name against the address.
#
# No gVisor RuntimeClass: the guard executes no model-produced code, it only
# reads a model's verdict.
#
# Manifests: _genie-guard-manifests.nix. Gating check: genie-guard-check.nix,
# over those manifests with the flag forced on.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
  sh = import ./_genie-guard-shared.nix;
  manifests = import ./_genie-guard-manifests.nix { inherit ren lib; };
in
{
  ren.kinds.cluster.k8s-ai-genie-guard = opt (t.submodule {
    options = {
      # Run genie-guard as an xmsg leaf pod in the genie namespace. Needs
      # images/sini/genie-guard and the xmsg-cluster-ca issuer.
      enable = opt t.bool false;
      # The host whose owner's xmsg is the leaf's hub; it takes the leaf from
      # the xmsg-leaves record this aspect emits.
      hub = opt t.str "bitstream";
      # More hosts whose owner's xmsg the leaf also pulls from, for development
      # and testing. The model endpoint stays the primary hub's.
      devHubs = opt (t.listOf t.str) [ ];
    };
  }) { };

  ren.aspects.k8s-ai-genie-guard = {
    # The hubs take the leaf from this record (features/dev/ai/xmsg.nix).
    xmsg-leaves =
      { cluster, ... }:
      let
        cfg = cluster.k8s-ai-genie-guard;
      in
      lib.optionals cfg.enable [
        {
          inherit (sh) identity;
          cluster = cluster.name;
          hubs = map (h: "${ren.host.${h}.system-owner.name}.${h}") ([ cfg.hub ] ++ cfg.devHubs);
          # It answers what it collects, and is sent nothing but guard requests.
          allow = [ "reply" ];
          targets = [ sh.name ];
        }
      ];

    # Declared with the flag off too, so the sops store holds the key before the pod
    # needs it and turning the flag on needs only the image.
    # The key the bitstream guard reads (services/ai/hyperqwen-client.nix);
    # generated there, so no generator here.
    age-secrets.age.secrets.genie-guard-api-key = {
      rekeyFile = ren.environment.dev.secretPath + "/hyperqwen/api-key.age";
      sopsOutput = {
        file = "genie-guard";
        key = "api-key";
      };
    };

    k8s-manifests =
      {
        config,
        cluster,
        images,
        xmsg-nodes ? [ ],
        ...
      }:
      manifests { inherit config cluster images xmsg-nodes; };
  };
}
