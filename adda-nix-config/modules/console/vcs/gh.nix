# vcs: GitHub token (sops) for Nix and gh, gh login on activation
{ ren, ... }:
{
  ren.aspects.vcs.os =
    { user, config, ... }:
    {
      sops.secrets.githubApiToken = {
        sopsFile = user.vcs.githubTokenSops;
        key = "token";
        format = "yaml";
        owner = user.name;
      };

      # Authenticates Nix itself (flake input fetches, `nix flake update`, etc.) against the GitHub API, so it
      # doesn't hit the low unauthenticated rate limit. `nix.settings.access-tokens` would embed the token in
      # plaintext in the world-readable Nix store (it becomes part of the /etc/nix/nix.conf derivation), so instead
      # render it into a runtime-only file and `!include` it; the token only ever touches disk outside the store.
      sops.templates."nix-github-access-tokens.conf".content = ''
        access-tokens = github.com=${config.sops.placeholder.githubApiToken}
      '';

      nix.extraOptions = ''
        !include ${config.sops.templates."nix-github-access-tokens.conf".path}
      '';
    };

  ren.aspects.vcs.homeManager =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    {
      # Logs `gh` into GitHub using the same token, so both `gh` and its git credential helper hit the GitHub API
      # authenticated instead of rate-limited.
      home.activation.githubCliLogin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${lib.getExe pkgs.gh} auth login --hostname github.com --with-token \
          < ${osConfig.sops.secrets.githubApiToken.path}
      '';
    };
}
