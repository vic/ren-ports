{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.nixgl.homeManager =
    {
      osConfig ? null,
      config,
      lib,
      ...
    }:
    {
      options.swarselsystems = {
        SecondaryGpuCard = lib.mkOption {
          default = "";
          type = lib.types.str;
        };
        isSecondaryGpu = lib.mkEnableOption "device has a secondary GPU";
      };
      config = {
        swarselsystems.enabledHomeModules = [ "nixgl" ];
        targets.genericLinux.nixGL = lib.mkIf (osConfig == null) (
          {
            inherit (inputs.nixgl) packages;
            defaultWrapper = "mesa";
            installScripts = [
              "mesa"
              "mesaPrime"
            ];
            vulkan.enable = false;
          }
          // lib.optionalAttrs config.swarselsystems.isSecondaryGpu {
            offloadWrapper = "mesaPrime";
            prime = {
              card = config.swarselsystems.secondaryGpuCard;
              installScript = "mesa";
            };
          }
        );
      };
    };
}
