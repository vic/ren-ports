{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects = {
    uni.includes = [ ren.aspects.work-home ]; # old nixos `home-manager.users.<mainUser>.imports = [ hm work ]`
    uni.homeManager =
      {
        globals-defs,
        config,
        osConfig ? null,
        ...
      }:
      let
        globals = sw.globalsOf globals-defs;
        confLib = sw.confLibOf { host = null; inherit globals config; inherit osConfig; };
      in
      {
      config.services.pizauth = {
        enable = true;
        accounts.uni = {
          authUri = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize";
          clientId = "08162f7c-0fd2-4200-a84a-f25a4db0b584";
          clientSecret = "TxRBilcHdC6WGBee]fs?QR:SJ8nI[g82";
          loginHint = "${confLib.getConfig.repo.secrets.local.uni.mailAddress}";
          scopes = [
            "https://outlook.office365.com/IMAP.AccessAsUser.All"
            "https://outlook.office365.com/SMTP.Send"
            "offline_access"
          ];
          tokenUri = "https://login.microsoftonline.com/common/oauth2/v2.0/token";
        };
      };
    };
    uni.nixos =
      {
        config,
        lib,
        ...
      }:
      {
        config =
          { }
          // lib.optionalAttrs (!config.swarselsystems.isMicroVM) {

          };
      };
  };
}
