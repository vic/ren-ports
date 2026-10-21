# hindsight homeManager half: den-law token, backfill tools, transcript renderer, hook scripts.
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
{
  ren.aspects.dev-ai-mcp-hindsight.homeManager =
    { host, user, config, pkgs, ... }:
    let
      h = import ./_hindsight-mcp/lib.nix { inherit lib pkgs host user config; };
    in
    {
      # The den-law token: a rekey target of the one generator in
      # k8s/ai/hindsight.nix (same rekeyFile, no generator here).
      # Declared here, so every user with this client is a target: the owner of the
      # read-write token, anyone else of their own read token. The path is the same
      # either way, so the MCP entry's bearerTokenFile does not depend on which.
      age.secrets.hindsight-token-den-law = {
        rekeyFile =
          h.root
          + "/.secrets/env/prod/hindsight/${
            if h.writer then "token-den-law.age" else "read-token-den-law-${user.name}.age"
          }";
        mode = "400";
        path = "${h.home}/.config/hindsight/den-law-token";
      };

      # Backfill tool for sessions that predate the hook, or that ended without
      # firing it. Overridden with THIS host's endpoint and bank rather than
      # carrying its own copy of them — the package's defaults exist so it runs
      # standalone, not so there are two places to change the address.
      home.packages = lib.optionals h.writer [
        (pkgs.local.hindsight-backfill.override {
          inherit (h.cfg) endpoint bank;
          inherit (h) tokenFile;
        })
        (pkgs.local.hindsight-handoff-reconcile.override {
          inherit (h.cfg) endpoint bank;
          inherit (h) tokenFile;
          repos = map (r: "${h.home}/${r}") h.cfg.handoffRepos;
        })
      ];

      # Transcript renderer, shared by the SessionEnd hook and the disk sweep so
      # both produce the SAME shape — a corpus assembled by two renderers is two
      # corpora. Derived from upstream's `transcript.ts`, which this deployment
      # does not install; the rules it encodes are theirs, the two divergences
      # below are ours and are measured.
      #
      # Keeps the ENGINEERING SUBSTANCE: requests, narration, and one compact
      # `action` turn per tool call naming the tool and its target. Drops
      # tool_result (outputs are mechanical noise), thinking, isMeta/isSidechain
      # lines, and Claude Code's own compaction summary — that last one arrives
      # as a plain type:"user" record with no flag but isCompactSummary, and it
      # recaps turns already retained, so keeping it extracts them twice.
      #
      # Measured on one 5.8 MB session: 2223 lines -> 643 turns, 386 KB (15x).
      # Across 90 sessions: 810 MB -> 11.6 MB (70x). Control in the same run:
      # 372 tool_use blocks in, 372 action turns out, on a FROZEN copy — the
      # live file is appended to while it is read, and two counts of the same
      # predicate minutes apart differ for that reason alone.
      #
      # DIVERGENCE 1 — <system-reminder> is load-bearing here, not insurance.
      # Upstream strips it against the day it moves; on this fleet it CARRIES
      # CLAUDE.md and the memory index, so leaving it in feeds the bank its own
      # injected context. Measured: 6 occurrences in, 0 out, with real content
      # surviving in the same run.
      #
      # DIVERGENCE 2 — a peer session's message arrives as type:"user".
      # Measured on one session: 30 of 72 user turns (42%) are other sessions
      # writing through <teammate-message>, so the extractor reads them as the
      # OWNER speaking. Their content is substantive, so they are re-labelled
      # rather than dropped. Left as "user" they become owner testimony, and
      # that false attribution then lives INSIDE the fact's own text, where no
      # tag filter and no tier can reach it.
      home.file.".claude/hindsight-episode.jq".source = ./_hindsight-mcp/episode.jq;

      # Session archiver. Written unconditionally so the disk sweep can call it
      # by hand; only WIRED as a hook when archiveHook is enabled.
      home.file.".claude/hindsight-archive.sh" = {
        executable = true;
        text = h.fill ./_hindsight-mcp/archive.sh (h.common // {
          inherit (h) renderer;
          strategy = h.cfg.episodeStrategy;
        });
      };

      # Recall helper. Written unconditionally so it can be run by hand for a
      # replay check; only WIRED as a hook when recallHook is enabled.
      home.file.".claude/hindsight-recall.sh" = {
        executable = true;
        text = h.fill ./_hindsight-mcp/recall.sh h.common;
      };
    };
}
