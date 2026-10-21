{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.gammastep.homeManager =
    {
      globals-defs,
      osConfig ? null,
      config,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { host = null; inherit globals config; inherit osConfig; };
      inherit (confLib.getConfig.repo.secrets.common.location) latitude longitude;
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "gammastep" ];
        services.gammastep = lib.mkIf ((osConfig != null) && !config.swarselsystems.isPublic) {
          inherit latitude longitude;
          enable = true;
          provider = "manual";
        };
        systemd.user.services.gammastep = confLib.overrideTarget "sway-session.target";
      };
    };
}
