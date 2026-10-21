# matrix-xmsg bot's xmsg node record, emitted at the host scope alone (own aspect, included by every host).
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
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
  ren.aspects.svc-matrix-xmsg-node-xmsg-nodes = {
    at = ren.kinds.host;
    xmsg-nodes =
    { environment, host, ... }:
    let
      cfg = host.svc-matrix-xmsg;
    in
    lib.optionals (cfg.rooms != [ ]) [
      {
        name = xl.nodeName host.name svcUser;
        address = "${host.name}.ts.${environment.domain}:${toString cfg.xmsgPort}";
        lanIp = builtins.head (ren.helpers.ipv4Of host);
        port = cfg.xmsgPort;
        identity = xl.spiffeOf host.name svcUser;
        owner = host.system-owner;
        allow = [ "send" "reply" ];
        guards = guardsOf cfg;
      }
    ];
  };
}
