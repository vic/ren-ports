# genie-xmsg: read-only option surface, node-key secrets, no-TCP assertion (see genie-xmsg.nix).
{ lib, ... }:
let
  l = import ./_genie-xmsg-lib.nix;
in
{
  ren.aspects.svc-ai-genie-xmsg.nixos =
    {
      config,
      environment,
      host,
      ...
    }:
    let
      cfg = host.svc-ai-genie-xmsg;
      keySecret = tier: {
        rekeyFile = host.secretPath + "/${l.keyName tier}.age";
        generator.script = "xmsg-identity";
        settings = {
          node = "${l.user tier}@${host.name}";
          san = "${host.name}.ts.${environment.domain}";
        };
        owner = l.user tier;
        group = l.user tier;
        mode = "0400";
      };
      svc = tier: config.systemd.services."xmsg@${tier}";
      tcpFlag =
        tier:
        lib.any (s: lib.hasInfix "--listen" (toString (s.serviceConfig.ExecStart or ""))) [
          config.systemd.services."xmsg@"
          (svc tier)
        ]
        || (svc tier).environment ? XMSG_LISTEN
        || config.systemd.services."xmsg@".environment ? XMSG_LISTEN;
    in
    {
      options.services.genie-xmsg = {
        runtimeDir = lib.mkOption {
          internal = true;
          readOnly = true;
          type = lib.types.attrsOf lib.types.str;
          default = lib.genAttrs l.tiers l.runtimeDir;
          description = "XDG_RUNTIME_DIR of each tier's units.";
        };
        fedPorts = lib.mkOption {
          internal = true;
          readOnly = true;
          type = lib.types.attrsOf lib.types.port;
          default = {
            ${host.system-owner.name} = cfg.ownerFedPort;
          }
          // lib.listToAttrs (map (tier: lib.nameValuePair (l.user tier) cfg.${tier}.fedPort) l.tiers);
          description = "Each node's federation port on this host, by node user.";
        };
        # Readable whether or not the keys are declared; genie-xmsg-check.nix reads it.
        keySecrets = lib.mkOption {
          internal = true;
          readOnly = true;
          type = lib.types.attrsOf lib.types.attrs;
          default = lib.genAttrs l.tiers keySecret;
        };
      };

      config = {
        xmsg.federationPorts = lib.listToAttrs (
          map (tier: lib.nameValuePair "${l.user tier}.${host.name}" cfg.${tier}.fedPort) l.tiers
        );

        assertions = map (tier: {
          assertion = !tcpFlag tier;
          message = "genie-xmsg: xmsg@${tier} must bind no TCP (no --listen, no XMSG_LISTEN): its bus is reachable only by its own uid over http.sock.";
        }) l.tiers;

        warnings = lib.optional (!cfg.nodeKeys) ''
          genie-xmsg: svc-ai-genie-xmsg.nodeKeys is off on ${host.name}, so the tiers' federation node keys are NOT declared.
          Set it, then run `agenix generate`, `git add` the .age and .crt files, and `agenix rekey`.
        '';

        age.secrets = lib.mkIf cfg.nodeKeys (
          lib.listToAttrs (map (tier: lib.nameValuePair (l.keyName tier) (keySecret tier)) l.tiers)
        );
      };
    };
}
