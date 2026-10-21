# agenix battery, user side: per-user identity secret on the system, agenix homeManager modules + rekey.
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
  inherit (ren.lib) and within not;
  identity =
    cls: group: { user, ... }:
    {
      age.secrets."user-identity-${user.name}" = {
        rekeyFile = user.secretPath + "/id_agenix.age";
        owner = user.name;
        # macOS has no same-named primary group (`staff`); chown user:user would fail and leave it root-owned
        inherit group;
        mode = "600";
        generator.script = "age-identity";
      };
    };
in
{
  ren.aspects.secrets-agenix-user = {
    at = and [ ren.kinds.user (not (within ren.kinds.droid)) ];
    # droid has no system agenix module: no per-user system identity secret
    nixos = { user, ... }: (identity "nixos" user.name { inherit user; });
    darwin = { user, ... }: (identity "darwin" "staff" { inherit user; });
  };
  ren.aspects.secrets-agenix-user-hm = {
    at = ren.kinds.user;
    homeManager =
      { user, fleet, osConfig, config, host ? null, mac ? null, droid ? null, ... }:
      let
        machine = if host != null then host else if mac != null then mac else droid;
        hasOsAge = osConfig ? age;
        hasUserIdentity = hasOsAge && osConfig.age.secrets ? "user-identity-${user.name}";
        userPubkeyPath = user.secretPath + "/id_agenix.pub";
      in
      {
        imports = [
          inputs.agenix.homeManagerModules.default
          inputs.agenix-rekey.homeManagerModules.default
          ../secrets/_generators-module.nix
        ];
        age = {
          identityPaths = lib.optionals hasUserIdentity [ osConfig.age.secrets."user-identity-${user.name}".path ];
          rekey = {
            inherit (fleet.secretsConfig) masterIdentities;
            storageMode = "local";
            generatedSecretsDir = ../../../.secrets/generated/${user.name}/${machine.name};
            localStorageDir = ../../../.secrets/rekeyed/${user.name}/${machine.name};
            # droid: osConfig has no `age`; agenix-rekey reads hostPubkey lazily so a missing path is safe
            hostPubkey = if hasUserIdentity then userPubkeyPath else if hasOsAge then osConfig.age.rekey.hostPubkey else userPubkeyPath;
          };
        };
      };
  };
}
