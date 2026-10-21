# sshOidcPrincipalsOf user -> opkssh OIDC principals allowed to log in as user.
# den default: a kanidm principal from identity.email (if set). A kind field default is a constant (README:315),
# so identity.sshOidcPrincipals is null = derive; an explicit list (even empty) wins.
{ ren, lib, ... }:
{
  ren.helpers.sshOidcPrincipalsOf =
    user:
    if user.identity.sshOidcPrincipals != null then
      user.identity.sshOidcPrincipals
    else
      lib.optional (user.identity.email != null) {
        provider = "kanidm";
        email = user.identity.email;
      };
}
