# genie-expert: the Opus tier of the @genie support bot. Claude Code runs as one
# OS user per sender tier, `genie-public` and `genie-trusted`, chosen by the
# sender's authenticated tier and never by a model. Neither holds any of the
# system owner's credentials: no wheel, no ssh login (so no forwarded agent), no
# gh/kube config, and no group that reaches the owner's files. Separate uids
# keep the tiers apart by construction: each has its own 0700 home and Claude
# state, and neither can reach the other's processes through /proc.
#
# Each tier's instance, genie-expert@<tier>, sees its own repos at
# /var/lib/genie/repos and its own memory at /var/lib/genie/memory, bound only
# inside that instance:
#   - trusted: the owner's checkouts (read-only bind mounts inside the 0700
#     trusted home) and the owner's ~/.claude/memory;
#   - public: clean clones of the PUBLIC repos at their published main, fetched
#     from GitHub by genie-public-repos (no working-tree extras), and the
#     curated support-memory/ of genie-agent, admitted by a merged PR.
#
# The token is genie's own (a `claude setup-token` token, revocable alone),
# root-owned and read only by systemd for LoadCredential; the instance exports
# it as CLAUDE_CODE_OAUTH_TOKEN. The sandbox settings deny the tools a read of
# the secret, the credential directory and /proc/*/environ, and unset the
# variable for sandboxed commands.
#
# Attach with `sudo -u genie-<tier> tmux -S /run/genie-expert-<tier>/tmux.sock attach`.
# Files: this (settings), genie-expert-system, -home, -services.
{ ren, lib, ... }:
let
  repoName = (ren.helpers.types.match "[A-Za-z0-9._-]+");
  privateRepos = [
    "den-ag-design"
    "gen-progress-report-v1"
  ];
  all = [
    "den-ag-design"
    "xmsg"
    "matrix-xmsg"
    "genie-agent"
    "genx"
    "gen"
    "gen-algebra"
    "gen-aspects"
    "gen-assemble"
    "gen-bind"
    "gen-class"
    "gen-delivery"
    "gen-demand"
    "gen-demo"
    "gen-differential"
    "gen-dispatch"
    "gen-edge"
    "gen-flake"
    "gen-graph"
    "gen-harness"
    "gen-identity"
    "gen-inspect"
    "gen-link"
    "gen-lsp"
    "gen-memo"
    "gen-merge"
    "gen-pipe"
    "gen-prelude"
    "gen-product"
    "gen-program"
    "gen-progress-report-v1"
    "gen-rebuild"
    "gen-resolve"
    "gen-rules"
    "gen-schema"
    "gen-scope"
    "gen-select"
    "gen-settings"
    "gen-types"
    "gen-vars"
    "gen-view"
  ];
in
{
  ren.kinds.machine.svc-ai-genie-expert = ren.lib.opt (lib.types.submodule {
    options = {
      checkouts = lib.mkOption {
        type = lib.types.listOf repoName;
        default = all;
        description = "The owner's checkouts under ~<system-owner>/Documents/repos/sini that the trusted tier sees read-only. A missing one fails its mount unit without blocking boot.";
      };
      publicRepos = lib.mkOption {
        type = lib.types.listOf repoName;
        # The checkouts whose GitHub visibility is PUBLIC (`gh repo view sini/<r>
        # --json visibility`, 2026-10-08): all but den-ag-design and
        # gen-progress-report-v1. List a repo here only once it is public.
        default = lib.subtractLists privateRepos all;
        description = "Public github.com/sini repos the public tier sees, as clean clones of main. Must include genie-agent, whose support-memory/ is the public memory.";
      };
    };
  }) { };
}
