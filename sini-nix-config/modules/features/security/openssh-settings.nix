{ ren, lib, ... }:
{
  # den settings.core.security.openssh.*; flat field named after the aspect.
  ren.kinds.machine.security-openssh = ren.lib.opt (lib.types.submodule {
    options = {
      exposure = lib.mkOption {
        type = lib.types.enum [
          "tailnet"
          "public"
        ];
        default = "tailnet";
        description = "SSH exposure: tailnet/LAN only (default) or public (break-glass jumpbox).";
      };
      externalPort = lib.mkOption {
        type = ren.helpers.types.port;
        default = 22;
        description = ''
          WAN port the gateway forwards to this host's sshd (port 22) when exposure
          is public. Give each public host a distinct port; the forward renderer
          refuses two forwards on the same WAN port.
        '';
      };
    };
  }) { };
}
