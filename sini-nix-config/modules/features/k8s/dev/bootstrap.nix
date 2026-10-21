# Settings for coder: cluster field k8s-dev-coder (den cluster.settings...coder.coder.bootstrap).
{ ren, lib, ... }:
{
  ren.kinds.cluster.k8s-dev-coder = ren.lib.opt (lib.types.submodule {
    options.bootstrap = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        First-run bootstrap mode for the Coder control plane.
  
        Coder requires the very first admin (owner) to be created through its
        email/password setup wizard — OIDC is NOT offered on that first-run screen
        (a Coder design choice), and setting CODER_DISABLE_PASSWORD_AUTH=true
        *before* the first user exists breaks the wizard. So bootstrapping an
        OIDC-only deployment is a two-phase flip, which this setting drives:
  
        - bootstrap = true  → password auth stays ENABLED so the setup wizard
          works. Use this for the very first deploy: create the first admin via the
          wizard, then sign in with kanidm OIDC (a `coder.admins` member becomes
          owner via the OIDC role mapping). The email/password account is then a
          break-glass owner that can be deleted.
  
        - bootstrap = false (default, production) → CODER_DISABLE_PASSWORD_AUTH=true,
          so the login page offers ONLY kanidm OIDC. Owners retain a hidden password
          backdoor regardless of this flag (Coder's deliberate anti-lockout
          behavior), so the bootstrap owner is never fully locked out.
  
        Flip this to false once the first user exists. GitHub login is disabled in
        both modes (CODER_OAUTH2_GITHUB_DEFAULT_PROVIDER_ENABLE=false).
      '';
    };
  }) { };
}
