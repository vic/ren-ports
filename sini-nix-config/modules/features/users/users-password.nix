# users: hashed password via agenix when <secretPath>/hashed-password.age exists.
{ lib, ... }:
{
  ren.aspects.users-enrich = {
    nixos =
      { user, ... }:
      lib.optionalAttrs (user.secretPath != null && builtins.pathExists (user.secretPath + "/hashed-password.age")) {
        age.secrets."user-${user.name}-password".rekeyFile = user.secretPath + "/hashed-password.age";
      };
    account =
      { user, ... }:
      lib.optionalAttrs (user.secretPath != null && builtins.pathExists (user.secretPath + "/hashed-password.age")) {
        hashedPasswordFile = "/run/agenix/user-${user.name}-password";
      };
  };
}
