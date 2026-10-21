# The upstream flake, not nixpkgs. nixpkgs tracks release tags and sat on v0.8.1
# (2026-06-12), which predates Nix definition/call extraction — that landed in
# 0849f28c (2026-06-27) and shipped in v0.9.0. Measured on den-hoag: v0.8.1 gives
# 7 Function nodes (all from the one Python file) and 8 CALLS edges; the flake's
# HEAD gives 39 Nix Function nodes and 38 CALLS. The flake exposes exactly one
# output we need, `packages.<system>.default`.
#
# `nixpkgs.follows` dedups the server's build nixpkgs onto ours. `pkgs` here is
# the overlay's build (pkgs/overlays.nix: this flake's package plus one local
# patch), NOT the channel's — see that overlay entry for what the patch fixes.
{ inputs, ... }:
{
  ren.aspects.dev-ai-mcp-codebase-memory = {
    flake-inputs.codebase-memory-mcp = {
      url = "github:DeusData/codebase-memory-mcp";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    agent-extensions =
      { pkgs, ... }:
      {
        type = "mcp";
        mcpServers.codebase-memory.command = "${inputs.codebase-memory-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/codebase-memory-mcp";
        skills.codebase-memory = ./_codebase-memory;
      };

    homeManager =
      { pkgs, lib, ... }:
      let
        cbm = inputs.codebase-memory-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default;
      in
      {
        home.packages = [ cbm ];

        # auto_index defaults to false, which leaves the graph empty until an
        # agent volunteers to index — the augmenter hook is inert against an
        # empty graph, so nothing ever nudges them. Indexing on session start
        # makes the bootstrap deterministic. The setting lives in the server's
        # own sqlite config, hence an idempotent activation step rather than a
        # managed file.
        home.activation.cbmAutoIndex = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # `config set` refuses while a codebase-memory process from a different
          # build is live, and an open agent session pins the old build across the
          # very switch that installs the new one — so an ordinary deploy started
          # from inside a session takes the whole generation down with it. The
          # write is idempotent and the next activation re-applies it, so warn and
          # carry on instead.
          run ${cbm}/bin/codebase-memory-mcp config set auto_index true \
            || warnEcho "codebase-memory-mcp: auto_index left unchanged (a live session holds a conflicting build); re-applied on the next activation"
        '';

        programs.git.ignores = [
          "/AGENTS.md"
          ".cbmignore"
        ];
      };
  };
}
