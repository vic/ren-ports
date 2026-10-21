# Emits one resolved-users entry per user; collected at host scope so host-level aspects can enumerate users.
{ ren, ... }:
{
  ren.aspects.users-resolved-user-emitter = {
    at = ren.kinds.user;
    resolved-users =
      { user, ... }:
      {
        inherit (user) name uid groups;
        sshKeys = map (k: k.key) user.identity.sshKeys;
        sshOidcPrincipals = ren.helpers.sshOidcPrincipalsOf user;
      };
  };
}
