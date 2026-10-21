# opkssh SERVER verifier. NixOS: the nixpkgs `services.opkssh` module wires sshd's
# AuthorizedKeysCommand + /etc/opk/{providers,auth_id}. darwin: opkssh-darwin.nix.
{ ren, ... }:
{
  ren.aspects.security-opkssh.nixos =
    { environment, ... }:
    {
      services.opkssh = {
        enable = true;
        providers = {
          kanidm = {
            issuer = "https://${ren.helpers.domainFor environment "kanidm"}/oauth2/openid/opkssh";
            clientId = "opkssh";
            lifetime = "24h";
          };
          # opkssh ships a shared Google client id (the nixpkgs module's own default).
          # Pinned here because setting `providers` replaces the default set (which
          # would otherwise drop google).
          google = {
            issuer = "https://accounts.google.com";
            clientId = "206584157355-7cbe4s640tvm7naoludob4ut1emii7sf.apps.googleusercontent.com";
            lifetime = "24h";
          };
        };
        # authorizations are contributed per-user by security-opkssh-authz.
      };
    };

  # Per-user opkssh authorizations from the user registry (den:
  # schema.user.includes). NEW aspect, no tsv row. `services.opkssh.authorizations`
  # is a list option, so per-(host,user) emissions concatenate. NixOS hosts only.
  ren.aspects.security-opkssh-authz = {
    at = ren.lib.and [
      ren.kinds.user
      (ren.lib.within ren.kinds.host)
    ];

    os =
      { environment, user, ... }:
      {
        services.opkssh.authorizations = map (p: {
          user = user.name;
          principal = p.email;
          issuer =
            if p.provider == "google" then
              "https://accounts.google.com"
            else
              "https://${ren.helpers.domainFor environment "kanidm"}/oauth2/openid/opkssh";
        }) (ren.helpers.sshOidcPrincipalsOf user);
      };
  };
}
