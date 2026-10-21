# xmsg home-manager half: programs.xmsg server, federation peers, genie-guard unit. Same aspect as xmsg.nix.
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
{
  ren.aspects.dev-ai-mcp-xmsg.homeManager =
    {
      config,
      host,
      is,
      osConfig,
      pkgs,
      xmsg-leaves,
      xmsg-nodes,
      ...
    }:
    let
      xl = import ./_xmsg-lib.nix { inherit lib; self = ../../../..; };
      sys = pkgs.stdenv.hostPlatform.system;
      leafNode =
        leaf:
        let
          m = builtins.match "spiffe://[^/]+/ns/([^/]+)/sa/([^/]+)" leaf.identity;
        in
        if m == null then
          throw "xmsg federation: leaf identity ${leaf.identity} is not spiffe://<domain>/ns/<ns>/sa/<sa>."
        else
          "${lib.elemAt m 1}.${lib.elemAt m 0}";
      # den read host.settings.services.matrix-xmsg.rooms (matrix-xmsg lane field).
      botEnabled = (host.dev-ai-mcp-xmsg-matrix-rooms or [ ]) != [ ];
      guardEnabled = botEnabled && config.home.username == host.system-owner.name;
      tier1Enabled = is ren.aspects.svc-ai-genie-tier1 host;
      guardExe = lib.getExe inputs.genie-agent.packages.${sys}.genie-guard;
      me = config.home.username;
      node = host.dev-ai-mcp-xmsg.federation.nodes.${me} or null;
      rootCa = xl.caCrt (xl.caDir + "/root.crt");
      self' = xl.nodeName host.name me;
      peers =
        lib.listToAttrs (
          map (
            p:
            lib.nameValuePair p.name {
              inherit (p) address;
              allow = p.allow or [ "send" "reply" "list" ];
              ca = rootCa;
              identities = [ p.identity ];
            }
          ) (lib.filter (p: p.name != self') xmsg-nodes)
        )
        // lib.listToAttrs (
          map (
            leaf:
            lib.nameValuePair (leafNode leaf) {
              address = "${leafNode leaf}.invalid:${toString node.port}";
              ca = rootCa;
              identities = [ leaf.identity ];
              leaf = true;
              inherit (leaf) allow targets;
            }
          ) (lib.filter (l: lib.elem self' l.hubs) xmsg-leaves)
        );
    in
    {
      assertions = map (p: {
        assertion = xl.trusts me p.owner;
        message = "xmsg federation: ${self'} would peer ${p.name}, a service of ${p.owner}, who is neither ${me} nor in trustedPairs with them.";
      }) (lib.filter (p: p ? owner) xmsg-nodes);

      programs.xmsg = {
        enable = true;
        package = lib.mkIf pkgs.stdenv.hostPlatform.isLinux pkgs.local.xmsg;
        server = {
          enable = pkgs.stdenv.hostPlatform.isLinux;
          svcExe = lib.optionalAttrs guardEnabled { genie-guard = guardExe; };
          federation = lib.mkIf (node != null) {
            enable = true;
            inherit (node) port;
            inherit peers;
            cert = xl.caCrt (host.secretPath + "/${xl.leafName me}.crt");
            key = osConfig.age.secrets.${xl.leafName me}.path;
          };
        };
        harnesses = lib.genAttrs [ "claude" "agy" "pi" "opencode" "hermes" ] (_: { enable = true; });
      };

      systemd.user.services.genie-guard = lib.mkIf guardEnabled {
        Unit = {
          Description = "genie-guard: guard-in verdicts for the @genie bot";
          After = [ "xmsg.service" ];
          Wants = [ "xmsg.service" ];
        };
        Service = {
          ExecStart = lib.escapeShellArgs [
            guardExe
            "--ninfer-url"
            host.dev-ai-mcp-xmsg.genieGuard.ninferUrl
            "--api-key-file"
            "%h/.config/hyperqwen/api-key"
          ];
          Restart = "on-failure";
          RestartSec = 10;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
