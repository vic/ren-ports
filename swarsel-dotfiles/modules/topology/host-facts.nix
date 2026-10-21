# host facts that channels read (emissions never read config); the `host-facts` aspect writes them to `swarselsystems.*`.
{ ren, lib, inputs, ... }:
let
  inherit (ren.lib) opt maybe;
  t = lib.types;
  sw = ren.helpers;
  # repo.secrets.local of a machine: hosts/.../secrets/pii.nix.enc (old common/pii.nix)
  piiOf =
    host:
    sw.importEncrypted (sw.secretsDirOf host + "/pii.nix.enc") {
      inherit inputs;
      inherit (inputs.nixpkgs) lib;
      inherit (inputs.topologyPrivate) topologyPrivate;
    };
  proxyHostOf = host: if host.proxyHost == null then host.name else host.proxyHost;
in
{
  ren.kinds.host = {
    proxyHost = maybe t.str; # null: the host proxies its own services
    isCloud = opt t.bool false;
    isImpermanence = opt t.bool false; # a guest reads its host's value (old nodes.<parent>.config)
    nodeRoles = opt (t.listOf t.str) [ ]; # roles this server fulfills (globals.general)
  };

  ren.helpers = {
    inherit piiOf proxyHostOf;
    # old swarselsystems.server.{netConfigPrefix,netConfigName} (server/infra/network.nix)
    netConfigPrefixOf = host: if host.isCloud then host.name else "home";
    netConfigNameOf =
      host: "${sw.netConfigPrefixOf host}-${(piiOf host).networking.localNetwork or ""}";
  };

  ren.aspects.host-facts = {
    at = ren.kinds.host;
    nixos =
      { host, ... }:
      {
        swarselsystems = {
          inherit (host) isCloud isImpermanence nodeRoles;
          proxyHost = proxyHostOf host;
        };
      };
  };
}
