# genie-experts: Claude subscription token pool for genie's expert pods (I10.3).
# One file per account under .secrets/env/prod/genie-experts/<tier>/<label>.age;
# the pool is the directory listing.
{ ren, lib, ... }:
let
  pool = ren.environment.prod.secretPath + "/genie-experts";
  tiers = [
    "trusted"
    "public"
  ];

  tokensIn =
    tier:
    let
      dir = pool + "/${tier}";
      files = lib.optionalAttrs (builtins.pathExists dir) (builtins.readDir dir);
    in
    map (f: {
      inherit tier;
      label = lib.removeSuffix ".age" f;
      rekeyFile = dir + "/${f}";
    }) (lib.filter (f: files.${f} == "regular" && lib.hasSuffix ".age" f) (lib.attrNames files));
in
{
  ren.aspects.k8s-ai-genie-experts-age-secrets.age-secrets.age.secrets = lib.listToAttrs (
    map (t: {
      name = "genie-experts-${t.tier}-${t.label}";
      value = {
        inherit (t) rekeyFile;
        sopsOutput = {
          file = "genie-experts";
          key = "${t.tier}-${t.label}";
        };
      };
    }) (lib.concatMap tokensIn tiers)
  );
}
