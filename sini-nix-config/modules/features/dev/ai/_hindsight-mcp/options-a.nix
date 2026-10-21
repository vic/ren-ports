# hindsight options, part 1 (endpoint, bank, recallHook). Merged with options-b in ../hindsight.nix.
{ lib }:
{
  endpoint = lib.mkOption {
    type = lib.types.str;
    default = "http://10.11.0.20:8888";
    description = ''
      Base URL of the hindsight dataplane API. Defaults to the axon
      cluster's private LoadBalancer address, reserved as
      `hindsight-internal` in that cluster's kubernetes-loadbalancers
      network — BGP-advertised to the LAN and not internet-routable. An IP
      rather than a name because the service has no HTTPRoute and therefore
      no service domain; give it one and this becomes a hostname.
    '';
  };

  bank = lib.mkOption {
    type = lib.types.str;
    default = "den-law";
    description = ''
      Bank to expose. hindsight serves one MCP endpoint per bank at
      `/mcp/<bank>/`, so this selects what the agent can see.

      ONE bank holds every tier, owner-ruled 2026-09-01. What keeps retired
      records and session evidence from reading as law is the `tier:` tag,
      not a separate store: every document carries one, derived from its
      ORIGIN rather than judged — `specs/adr/` layout for the ADR corpus,
      each memory file's own frontmatter `type:` for the rest. Backfilled
      across 253 documents on that basis, which put `tier:law` on 39 of
      them, not on the 224 a tag-reading heuristic had proposed.
    '';
  };

  recallHook = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Install a UserPromptSubmit hook that recalls from the bank on every
      prompt and injects the results as context.

      Default false. This is a READ path — it cannot write to the bank — but
      it changes every prompt in every session, so it is opt-in and wants
      evidence first: the replay oracle (O3) green before it is worth
      paying for on each turn. The MCP tools above already make recall
      available on demand; this only removes the need to ask.

      O3 must include a run under LOAD, not just a quiet one. Measured
      2026-08-31 during a backfill: recall exceeded 20s and the dataplane
      then refused connections for 135s. The script fails open, so the cost
      of that is not a broken session — it is dead time per prompt followed
      by silence, which is indistinguishable from a bank that had nothing
      to say.

      THE BUDGET IS NOW 75s WORST CASE (5 health + 10 stats + 60 recall),
      up from 17s. Not padding: hindsight's own server trace on 2026-09-01
      shows one recall at 24.128s, of which 24.036s is the CROSS-ENCODER
      scoring 289 candidates to return five. Retrieval was 0.029s. The old
      10s recall budget sat BELOW that floor, so under load it would time
      out every time — spending 10s to inject nothing, the worst of both.
      This makes the ceiling honest rather than making it fast, and it is
      precisely why this hook stays off until O3 measures what 75s per
      prompt actually costs.

      The number moves as the bank grows: candidates scale with the corpus,
      reranking scales with candidates, and session capture adds corpus.
    '';
  };
}
