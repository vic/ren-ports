# ~/.claude state buckets: persistHome (kept across a home wipe), cacheHome (regenerable), replicateHome.
{ ... }:
{
  ren.aspects.dev-ai-agents-claude = {
    # Mutable local state — survives a home wipe, in /persist, NOT synced.
    # memory + projects are replicated (replicate.nix); they live here too so a
    # wipe doesn't force Syncthing to re-pull the whole set from peers.
    persistHome = {
      directories = [
        ".claude/memory"
        ".claude/projects"
        ".claude/plugins"
        ".claude/file-history"
        ".claude/tasks"
        ".claude/todos"
        ".claude/teams"
        ".claude/workflows"
        ".claude/backups"
        ".claude/sessions"
        ".claude/jobs"
      ];
      files = [
        ".claude/.credentials.json"
        ".claude/history.jsonl"
        # Not under .claude/ — CC's main state file: per-project history, MCP server
        # approvals, onboarding state, and the cached GrowthBook feature payload the
        # env flag falls back to. With telemetry off that payload is never
        # refetched, so losing this file permanently disables every gated feature.
        ".claude.json"
      ];
    };

    # Regenerable scratch — /cache dataset, not backed up. Lost-on-wipe is fine.
    cacheHome = {
      directories = [
        ".claude/cache"
        ".claude/paste-cache"
        ".claude/session-env"
        ".claude/shell-snapshots"
        ".claude/statsig"
        ".claude/debug"
        ".claude/daemon"
        ".claude/ide"
      ];
      files = [
        ".claude/stats-cache.json"
        ".claude/mcp-needs-auth-cache.json"
        ".claude/.last-cleanup"
        ".claude/daemon.log"
      ];
    };

    replicateHome.directories = [
      ".claude/memory"
      ".claude/projects"
    ];
  };
}
