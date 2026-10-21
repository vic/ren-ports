# beads: an AI-supervised issue tracker for coding agents. Its own aspect in the
# codebase-memory-mcp mold: the binaries, the viewer, the Claude Code plugin, the tool
# permission, and the pinned workspace. Skill/hook-based, not an MCP server.
# Split: beads-hooks.nix (SessionStart drift check + boot text), _beads/ (script bodies).
#
# The tracker is br (github:Dicklesworthstone/beads_rust) — SQLite + JSONL,
# resolving its workspace from BEADS_DIR below. It replaced bd
# (github:gastownhall/beads, Dolt-backed) at the 2026-08-25 cutover; the
# migration record is docs/runbooks/beads-dolt-to-rust.md plus the tracker's
# own den-hoag-bamt bead. The upstream bd→br migration skill stays registered
# through the cutover tail and retires with the runbook's post-validation
# cleanup.
{ inputs, ... }:
{
  ren.aspects.dev-ai-tools-beads = {
    agent-extensions =
      { pkgs, ... }:
      {
        type = "plugin";
        marketplace = {
          name = "beads-rust";
          src = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.beads-rust.src;
          pluginId = "beads@beads-rust";
          enabled = false;
        };
        skills = {
          beads = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.beads-rust.src;
        };
      };

    homeManager =
      { config, pkgs, ... }:
      let
        llm = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
        beadsDir = "${config.home.homeDirectory}/Documents/repos/sini/den-ag-design/.beads";
      in
      {
        home.packages = [
          # `br` comes from the numtide collection rather than beads_rust's own
          # flake: that flake pulls a fenix nightly toolchain and crane, and
          # ships no flake.lock.
          llm.beads-rust
          llm.beads-viewer
        ];

        programs.claude-code = {

          # THE PLUGIN IS REGISTERED BUT NOT ENABLED, and the reason is its skill.
          # br's plugin is nothing but `.claude/skills/br/SKILL.md` (367 lines; no
          # commands, no hooks), and that file's "Critical Rules for Agents" table
          # states two rules this fleet has measured false:
          #
          #   "ALWAYS use --json"  — inverted. --json is for a PROGRAM consumer;
          #     the model gets text. Owner-ruled 2026-08-25.
          #   "--format toon for reduced tokens" — measured on this tracker, TOON is
          #     LARGER than JSON (ready: 1,444,234 B toon vs 1,439,726 B json;
          #     blocked: 324,714 vs 323,974) and ~30x larger than native text.
          #     TOON dedups repeated KEYS; a bead payload is dominated by free-text
          #     description VALUES, so there is nothing for it to dedup.
          #
          # A Critical-Rules table is the strongest guidance shape a skill has, so
          # this cannot be counter-argued from a hook — it is dropped instead. The
          # command reference it also carried is available on demand and better
          # scoped: `br robot-docs guide` is 52 lines and says "--json ... for
          # scripts", which is the correct boundary.
          settings.enabledPlugins."beads@beads-rust" = false;

          # Upstream's own migration guidance, registered as a plain skill rather
          # than via br's plugin — it lives at skills/ in the source tree, outside
          # the plugin's .claude/skills/, so it carries none of the colliding
          # `beads:` plugin surface.
          skills.bd-to-br-migration = "${llm.beads-rust.src}/skills/bd-to-br-migration";

          settings = {
            permissions.allow = [
              "Bash(br *)"
            ];

            # Without BEADS_DIR, `br` resolves its workspace from the CWD, so any
            # agent command that cd's elsewhere first loses the tracker, and the
            # body-edit idiom (`br show > body.md`, append, write back) TRUNCATES THE
            # FILE BEFORE the resolution error, so the read fails silently into a
            # clobber. br has no `-C` flag at all, so this variable is the whole
            # mechanism (`--db` exists for per-invocation overrides). Safe as a single
            # global: the tracker for every gen-* repo by ruling, the only .beads
            # workspace in the tree. It lives beside the ADRs and specs it cites
            # rather than in den-hoag, which ADR-0002 freezes.
            env.BEADS_DIR = beadsDir;
          };
        };
      };
  };
}
