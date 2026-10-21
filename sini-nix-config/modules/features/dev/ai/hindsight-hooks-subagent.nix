# hindsight SubagentStart arm: recall standing law into a starting subagent's own context.
{ lib, ... }:
{
  ren.aspects.dev-ai-mcp-hindsight.homeManager =
    { host, user, config, pkgs, ... }:
    let
      h = import ./_hindsight-mcp/lib.nix { inherit lib pkgs host user config; };
    in
    {
      # ★★★ A SUBAGENT IS STARTING — RECALL INTO ITS OWN CONTEXT, BEFORE ITS FIRST PROMPT.
      # This is the beat the orchestrator cannot cover: by the time it dispatches, the
      # brief is already written, so a recall there informs nobody in time and never
      # reaches the agent. `SubagentStart` injects into the SUBAGENT's context
      # (docs, hooks#subagentstart) and is the only event that does.
      # ★★ WHY A HOOK AND NOT AN INSTRUCTION: the agents hold `recall` themselves, and an
      # instruction to use it is exactly what was measured to fail — 0 recalls across 14
      # dispatches in one session, with the instruction sitting in context the whole time.
      # A rule that depends on remembering has now failed twice, measured. This makes it
      # mechanical.
      # ★ EACH ROLE RECALLS ON ITS OWN SUBJECT — the payload carries `agent_id` and
      # `agent_type`, never the task prompt, so a per-role query is the available
      # granularity. The agent refines from there with its own `recall`.
      # ★★★ THE ROLE IS NOT IN THE PAYLOAD FOR A NAMED TEAMMATE, so no MATCHER can select
      # on it. Claude Code 2.1.285 matches SubagentStart against `agent_type`, and a
      # teammate's `agent_type` is its NAME (`mgnv3-q-build`); its role lives in the team
      # registry `teams/*/config.json` (`members[].agentType`, written before the spawn)
      # and in the sidecar `subagents/agent-a<name>-<16 hex>.meta.json` as
      # `customAgentType` beside `"agentType": "<name>"`, which lands up to ~7s AFTER the
      # hook fires — so the registry is read first (`from=config`) and the sidecar is a
      # bounded fallback (`from=sidecar`, or `from=timeout` when it never appears). The payload's `agent_id` does not reliably
      # name that file (a teammate's reads `<name>@session-<id>`), so the arm finds the
      # sidecar by name and checks `agentType`; the log line carries the raw `id=`. Measured
      # across 2322 sidecars: 1908 of 1911 gen-role teammates carry a non-role name in
      # `agentType`, so per-role matchers never fired for them. One unmatched arm
      # reads the role from the sidecar and falls back to `agent_type`, which IS the role
      # for an unnamed `subagent_type` dispatch.
      # ★★★ AND THE FORMER `mcp_tool` ARMS NEVER CONNECTED: 296 of 296 recorded "MCP
      # server 'plugin_hm_hindsight' not connected". The hook looks the server up by its
      # CLIENT name, and a plugin's client is named `plugin:hm:hindsight` (claude-code
      # keys plugin servers `plugin:<plugin>:<server>`); `plugin_hm_hindsight` is the
      # tool-NAMESPACE spelling, which names no client. This arm needs no MCP client at
      # all: it recalls over the dataplane REST API, like hindsight-recall.sh.
      # ★★ `types` IS ON EVERY INPUT. An observation can invert its source and inherit
      # its `tier:` tag (den-hoag-mgnv3); replayed with these inputs the role queries
      # injected 1-2 observations each without the filter, 0 with it.
      # ★★ VERIFY BEFORE TRUSTING IT — this event fails silently in two ways (see the
      # PreToolUse block). Read a SUBAGENT's transcript, never the parent's, and confirm
      # the recalled text is present before its first tool call. Every firing also
      # appends one line to ~/.claude/hindsight-subagent.log naming the role, where it
      # came from, and the outcome, so "never fired" and "fired, delivered nothing" are
      # distinguishable.
      # ★★ THE 90s TIMEOUT IS MEASURED, NOT PADDING. From hindsight's OWN server trace
      # on 2026-09-01, not from a client stopwatch:
      #     [2] parallel retrieval          0.029s  -> 289 candidates
      #     [4] reranking [cross-encoder]  24.036s  -> 289 scored
      #     total                          24.128s
      # Recall latency is the CROSS-ENCODER, not the LLM and not the network: the
      # reranker scores every candidate to return five. The first version allowed 20s,
      # which under that load did not merely risk failing — it failed EVERY time.
      # ★ And it fails toward SILENCE. A timed-out recall leaves the agent starting with
      # no standing law and nothing to say so, which is the defect this block exists to
      # remove. A slow dispatch beats a quiet one.
      # ★ It gets SLOWER AS THE BANK GROWS — candidates scale with the corpus and the
      # reranker scales with candidates, so session capture moves this number. Re-read
      # the SERVER trace before trusting 90; a client stopwatch cannot separate rerank
      # time from queue wait, and under a backfill it is nearly all queue wait.
      programs.claude-code.settings.hooks.SubagentStart = [
        {
          hooks = [
            {
              type = "command";
              command = "${h.subagentRecall}";
              timeout = 240;
            }
          ];
        }
      ];
    };
}
