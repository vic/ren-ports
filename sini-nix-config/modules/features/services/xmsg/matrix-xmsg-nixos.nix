# matrix-xmsg service body (settings in matrix-xmsg.nix). Trust follows kanidm `admins` via idm-users.
{ ren, lib, inputs, ... }:
let
  adminGroup = "admins";
  xl = import ../../dev/ai/_xmsg-lib.nix { inherit lib; self = inputs.self; };
  svcUser = "matrix-xmsg";
  guardsOf =
    cfg:
    lib.optional (
      cfg.screenMentions
      || cfg.screenSolicited
      || lib.any (r: r.screenMentions == true) (lib.attrValues cfg.roomRoutes)
    ) cfg.guardRef;
in
{
  ren.aspects.svc-matrix-xmsg.nixos =
  {
    config,
    environment,
    host,
    idm-users,

    k3s-nodes,
    pkgs,
    xmsg-leaves,
    xmsg-nodes,
    ...
  }:
  let
    cfg = host.svc-matrix-xmsg;
    self' = xl.nodeName host.name svcUser;
    owner = xl.nodeName host.name host.system-owner;
    mxid = name: "@${name}:${environment.domain}";
    # The environment whose kanidm serves this host's (dev delegates to prod).
    idpEnv = (environment.services.kanidm or { }).delegateTo or null;
    trusted = lib.sort lib.lessThan (
      lib.unique (
        cfg.extraTrustedMxids
        ++ map (u: mxid u.name) (
          lib.filter (
            u:
            u.environment == (if idpEnv != null then idpEnv else environment.name)
            && lib.elem adminGroup u.groups
          ) idm-users
        )
      )
    );
    rootCa = xl.caCrt (xl.caDir + "/root.crt");
    # The system owner's nodes (policies/xmsg.nix collects them here).
    ownerNodes = lib.filter (n: n.name != self' && !(n ? guards)) xmsg-nodes;
    # The pod leaves this bot screens through, by the node part of each guard ref.
    guardNodes = map (g: lib.last (lib.splitString "@" g)) (guardsOf cfg);
    leafNodeOf =
      leaf:
      let
        m = builtins.match "spiffe://[^/]+/ns/([^/]+)/sa/([^/]+)" leaf.identity;
      in
      "${lib.elemAt m 1}.${lib.elemAt m 0}";
    leaves = lib.filter (l: lib.elem (leafNodeOf l) guardNodes) xmsg-leaves;
    leafRules = lib.concatMapStrings (
      leaf:
      lib.concatMapStrings
        (n: ''
          ip saddr ${n.ip} tcp dport ${toString cfg.xmsgPort} accept comment "xmsg leaf ${leafNodeOf leaf} of ${self'}: ${n.hostname}"
        '')
        (lib.sort (a: b: a.hostname < b.hostname) (lib.filter (n: n.clusterName == leaf.cluster) k3s-nodes))
    ) leaves;
    leafSecretName = xl.leafName svcUser;
  in
  {
    imports = [ inputs.matrix-xmsg.nixosModules.default ];

    warnings = lib.optional (cfg.rooms == [ ]) ''
      matrix-xmsg: settings.services.matrix-xmsg.rooms is empty on ${host.name}, so the @genie bot is NOT enabled.
      Run `agenix generate` (once, for the token), then `matrix-bot-provision '#support:${environment.domain}'` and set the room ID it prints.
    '';

    # Declared before any room is set: the token must exist to join one.
    age.secrets.matrix-genie-token = {
      rekeyFile = host.secretPath + "/matrix-genie-token.age";
      generator.script = "synapse-bot-token";
      settings = {
        namespace = "matrix";
        workload = "deploy/synapse";
        user = "genie";
        secretsFile = "/secrets/secrets.yaml";
      };
    };

    # E2EE (matrix-xmsg M36): the crypto store's passphrase, the running bot's
    # credential; and the recovery key, which unlocks the cross-signing keys in
    # secret storage and the room-key backup, read only by the one-shot
    # matrix-xmsg-e2ee-setup unit. Both are read by systemd (LoadCredential).
    age.secrets.matrix-xmsg-store-key = lib.mkIf (cfg.rooms != [ ]) {
      rekeyFile = host.secretPath + "/matrix-xmsg-store-key.age";
      generator.script = "rfc3986-secret";
    };
    age.secrets.matrix-xmsg-recovery-key = lib.mkIf (cfg.rooms != [ ]) {
      rekeyFile = host.secretPath + "/matrix-xmsg-recovery-key.age";
      generator.script = "rfc3986-secret";
    };

    age.secrets.${leafSecretName} = lib.mkIf (cfg.rooms != [ ]) (
      xl.leafSecret {
        inherit config host;
        user = svcUser;
      }
    );

    xmsg.federationPorts = lib.mkIf (cfg.rooms != [ ]) { ${self'} = cfg.xmsgPort; };

    # The pod leaves' cluster nodes, on this node's port only. Peers come over the
    # tailnet, which is trusted (core.network.tailscale), or loopback.
    networking.nftables.enable = lib.mkIf (leafRules != "") true;
    networking.firewall.extraInputRules = lib.mkIf (leafRules != "") leafRules;

    services.matrix-xmsg = lib.mkIf (cfg.rooms != [ ]) {
      enable = true;
      package = inputs.matrix-xmsg.packages.${pkgs.stdenv.hostPlatform.system}.default;
      homeserverUrl = "https://${ren.helpers.domainFor environment "matrix"}";
      botMxid = mxid "genie";
      ownerMxid = mxid "json";
      accessTokenFile = config.age.secrets.matrix-genie-token.path;
      storePassphraseFile = config.age.secrets.matrix-xmsg-store-key.path;
      recoveryKeyFile = config.age.secrets.matrix-xmsg-recovery-key.path;
      # The system user matrix-xmsg, on its own node; xmsgSocket is the module's
      # default, that node's socket dir.
      dynamicUser = false;
      user = svcUser;
      trustedMxids = trusted;
      inherit (cfg)
        rooms
        guardRef
        screenMentions
        screenSolicited
        ;
      # Both refs carry the owner's node name (xmsg README 7.0), so an expert of the
      # same name elsewhere in view never makes them ambiguous.
      expertRef = "${cfg.expertRef}@${owner}";
      roomRoutes = lib.mapAttrs (
        _: r:
        {
          expertRef = "${r.expertRef}@${owner}";
        }
        // lib.optionalAttrs (r.screenMentions != null) { inherit (r) screenMentions; }
      ) cfg.roomRoutes;
      openThreadNodes = map (n: n.name) ownerNodes;

      xmsg = {
        enable = true;
        package = pkgs.local.xmsg;
        federation = {
          enable = true;
          # Peers reach it by its tailnet name, and same-host ones over loopback,
          # so it binds every address; the firewall admits the pods' nodes only.
          listenAddress = "0.0.0.0";
          port = cfg.xmsgPort;
          cert = xl.caCrt (host.secretPath + "/${leafSecretName}.crt");
          key = config.age.secrets.${leafSecretName}.path;
          peers =
            lib.listToAttrs (
              map (
                n:
                lib.nameValuePair n.name (
                  xl.caPeer rootCa [
                    "send"
                    "reply"
                    "list"
                  ] n
                )
              ) ownerNodes
            )
            // lib.listToAttrs (
              map (
                leaf:
                lib.nameValuePair (leafNodeOf leaf) {
                  address = "${leafNodeOf leaf}.invalid:${toString cfg.xmsgPort}";
                  ca = rootCa;
                  identities = [ leaf.identity ];
                  leaf = true;
                  inherit (leaf) allow targets;
                }
              ) leaves
            );
        };
      };
    };
  };

}
