# hindsight (github:vectorize-io/hindsight): agent memory over the `den-law`
# bank — the fleet's standing operating law, stored verbatim.
#
# REMOTE MCP, not a local process: the server runs in the axon cluster and is
# reached over the private LoadBalancer, so this declares a `url` rather than a
# `command`. claude.nix routes url-bearing servers to the http transport.
#
# WRITE POSTURE. The standing ruling from the 2026-08-28 evaluation is that
# curation is the write path's property: auto-capturing adversarial transcripts
# would bank seeded defects and self-assessment prose as law. New law enters by
# the owner editing a memory file.
#
# ★ THAT RULING WAS AMENDED (owner, 2026-09-01): session capture is ADMITTED, to
# ONE bank, segmented by a `tier:` tag rather than by a second bank. The ground
# it rested on is unchanged and is now carried by the tier and the strategy
# instead of by exclusion — an episode is EVIDENCE and says so, law is the
# owner's to write, and the two are separable at recall (`tag_groups` takes
# AND/OR/NOT, verified against this bank by result identity, not by count).
# A second bank was considered and rejected in the same sitting: the mission
# attaches to the WRITE PATH, which a named retain strategy already gives, and
# splitting the store would prevent cross-tier consolidation.
#
#   HELD HERE — upstream's plugin hooks Stop and carries a retain cursor; this
#   deployment installs neither. `archiveHook` below is the equivalent path, on
#   SessionEnd rather than Stop, ON since 2026-09-01, and reasoned out with the
#   evidence that turned it on at that option.
#
#   HELD ON THE BANK, NOT HERE — `mcp_enabled_tools` was null, and null means
#   ALL, so `retain`, `update_bank`, `clear_memories` and `delete_bank` were
#   every bit as reachable as `recall`. Narrowed to the 15 read tools by hand on
#   2026-08-31, verified through a FRESH MCP session rather than the PATCH's
#   status code: 36 tools exposed before, 15 after. Read-only is now a property
#   rather than a posture — but nothing in this tree asserts it, and no rebuild
#   would restore it if someone set it back. See the note below on why it is not
#   declared here.
#
#   Prose could never have held that line: the `retain` tool's own description
#   opens "Use this tool PROACTIVELY whenever the user shares:", which the agent
#   reads at the moment of decision, while the skill's do-not-retain rule sits a
#   document away. The bank's audit log is also off, so a write that does happen
#   leaves no trace to find afterwards.
#
# Retaining the memory files is NOT mechanised. No unit in this tree does it —
# an earlier revision of this comment credited an "uplink sync unit" that does
# not exist — so it is an agent run by hand, and the bank's contents are
# therefore only as reviewed as that run was.
#
# BANK CONFIGURATION IS NOT MANAGED FROM HERE, and that is deliberate. Missions,
# dispositions, the observation switch and the tool allowlist are properties of
# the BANK — one shared object in the cluster. This aspect is a CONSUMER of that
# bank and ships to every dev host, so applying config from here would make
# three hosts writers on one resource, and hosts on different generations would
# flap the bank's configuration on each boot with the losing write silent.
# Built, measured and rejected on 2026-08-31 for that reason. If it is worth
# declaring, it belongs beside the service in
# aspects/kubernetes/services/ai/hindsight.nix, under exactly one writer.
{ ren, lib, ... }:
let
  opts = (import ./_hindsight-mcp/options-a.nix { inherit lib; }) // (import ./_hindsight-mcp/options-b.nix { inherit lib; });
in
{
  ren.kinds.machine.dev-ai-mcp-hindsight = ren.lib.opt (lib.types.submodule { options = opts; }) { };

  ren.aspects.dev-ai-mcp-hindsight = {
    # Split by concern: hindsight-agent.nix (MCP entry), hindsight-hm.nix (files, secret),
    # hindsight-hooks*.nix (claude-code hooks), hindsight-linux.nix (reconcile units).
    # Shell/jq bodies live in _hindsight-mcp/ and are filled from _hindsight-mcp/lib.nix.
  };
}
