# gen-agents: the four recurring subagent roles of the gen/den architecture effort,
# declared once. Tool restriction: gen-gate and gen-scout get no Edit tool. MCP tools
# are listed by name, never as `mcp__<server>__*`. The shared half is single-sourced:
# each role is head + shared-measurement + role body + shared-protocol.
{ ren, ... }:
{
  ren.aspects.dev-ai-skills-gen-agents.agent-extensions =
    { lib, pkgs, ... }:
    {
      type = "skill";
      agents = {
        gen-scout = ren.helpers.genAgent pkgs lib "scout";
        gen-gate = ren.helpers.genAgent pkgs lib "gate";
        gen-spec = ren.helpers.genAgent pkgs lib "spec";
        gen-build = ren.helpers.genAgent pkgs lib "build";
      };
    };
}
