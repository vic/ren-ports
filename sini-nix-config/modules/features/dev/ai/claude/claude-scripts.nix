# ~/.claude hook scripts (static bodies in _claude/*.sh). Retired: `.claude/env.sh` (CC never
# sources it; CLAUDE_ENV_FILE in claude-settings.nix is the supported mechanism).
{ ... }:
{
  ren.aspects.dev-ai-agents-claude.homeManager = {
    # SubagentStop: make a silent idle visible, and name the correct next move.
    # Records the stop and states the rule; does not adjudicate whether a report arrived.
    home.file.".claude/subagent-stop.sh" = {
      executable = true;
      text = builtins.readFile ./_claude/subagent-stop.sh;
    };

    # ONE LEAN BUDGET LINE per firing: state and the tripped gate, never the rules (those live
    # in den-ag-design STATUS/RESUME-PROMPT-ARCH.md). Gates: ctx>=90 close out, ctx>=75 no fresh
    # subjects, 7d>=95 clean closeout (weekly outranks context). Owner-ruled 2026-09-01/02.
    home.file.".claude/budget.sh" = {
      executable = true;
      text = builtins.readFile ./_claude/budget.sh;
    };

    # PreCompact's STDOUT IS THE SUMMARIZER'S INPUT, NOT THE AGENT'S (claude-code 2.1.292);
    # exit 2 is the only lever on the agent.
    home.file.".claude/pre-compact.sh" = {
      executable = true;
      text = builtins.readFile ./_claude/pre-compact.sh;
    };

    # PreToolUse/Bash: the prose law that must hold every time — pkill -f, self-matching
    # pgrep waits, the nix memory cap, and the zsh idioms that fail silently.
    home.file.".claude/bash-guard.sh" = {
      executable = true;
      text = builtins.readFile ./_claude/bash-guard.sh;
    };

    home.file.".claude/subagent-brief.sh" = {
      executable = true;
      text = builtins.readFile ./_claude/subagent-brief.sh;
    };

    home.file.".claude/load-direnv.sh" = {
      executable = true;
      text = builtins.readFile ./_claude/load-direnv.sh;
    };
  };
}
