# opkssh CLIENT tooling for the machines you SSH *from* (workstations + darwin).
# Installs the `opkssh` CLI plus provider config so `opkssh login` mints an
# OIDC-backed short-lived SSH cert against kanidm (default) or Google. The
# server-side verifier lives in core/security/opkssh.nix; this is the client
# counterpart. Attached via roles.workstation / roles.darwin-workstation only
# (NOT roles.dev — that reaches slab/droid, which has no opkssh).
{ ren, ... }:
{
  ren.aspects.dev-security-opkssh-client = {
    # (the ID Token exp) instead of `Valid: forever`, and load the cert into the
    # ssh-agent (SSH_AUTH_SOCK) with a matching lifetime. The real expiry is what
    # lets ssh-agent-mux proxy the cert on the RELEASED ssh-key 0.6.7 (see
    # ssh-agent-mux.nix); the agent-add makes `opkssh-login` self-contained and
    # the agent drops the key when the cert expires. Client-only overlay
    # (workstations); the server verifier is unaffected by these changes.
    # Upstream: sini/opkssh feat/cert-expiry-and-agent (PRs pending).
    nixpkgs-overlays = { ... }: [
      (final: prev: {
        opkssh = prev.opkssh.overrideAttrs (_old: {
          version = "0.16.0-unstable-2026-08-13";
          src = final.fetchFromGitHub {
            owner = "sini";
            repo = "opkssh";
            rev = "86ebb35ada989197ce83c8eb1673974866536d7a";
            hash = "sha256-Gnr2yks/dZC+hrlGzimane4j2ZmvktfnvD3vuzEA774=";
          };
          vendorHash = "sha256-Qlk9zkElpCIpntMDNU5f+5YK2C2Jnc7Lp6uDUYFgQ2Q=";
          # main carries integration tests that shell out to a real `sshd`, which
          # isn't present in the Nix build sandbox ("exec: sshd not found"). The
          # unit tests (incl. sshcert) are run against the fork out-of-band.
          doCheck = false;
        });
      })
    ];

    homeManager =
      { pkgs, environment, ... }:
      let
        idmDomain = ren.helpers.domainFor environment "kanidm";
        kanidmIssuer = "https://${idmDomain}/oauth2/openid/opkssh";
      in
      {
        home.packages = [ pkgs.opkssh ];

        # Upstream home-manager has no `programs.opkssh` module, so write the
        # client provider config by hand. This is the swarsel-proven config.yml
        # format: `opkssh login` reads it and offers `default_provider` (kanidm)
        # with google available by alias.
        home.file.".opk/config.yml".text = ''
          default_provider: kanidm
          providers:
            - alias: kanidm
              issuer: ${kanidmIssuer}
              client_id: opkssh
              scopes: openid email profile groups
              redirect_uris:
                - http://localhost:3000/login-callback
                - http://localhost:10001/login-callback
                - http://localhost:11110/login-callback
            - alias: google
              issuer: https://accounts.google.com
              client_id: 206584157355-7cbe4s640tvm7naoludob4ut1emii7sf.apps.googleusercontent.com
        '';

        # config.yml above is the preferred UX (plain `opkssh login`). The
        # `--provider` alias below is the guaranteed fallback (the documented
        # datosh recipe) that works regardless of whether the pinned opkssh
        # version (currently 0.14.x in nixpkgs) honors the config file — pending
        # hands-on confirmation of its config-file support at e2e
        # Moved shellAliases to OS-specific blocks below to handle socket paths
      };
  };
}
