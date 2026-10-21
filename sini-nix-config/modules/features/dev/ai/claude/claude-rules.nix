# User-scope rules (~/.claude/rules/): load in every project and reach subagents.
# bash-guard.sh enforces the detectable half; these carry the reasons.
{ ... }:
{
  ren.aspects.dev-ai-agents-claude.homeManager = {
    programs.claude-code.rules = {
      shell-zsh = builtins.readFile ./_claude/rules-shell-zsh.md;
      nix-eval = builtins.readFile ./_claude/rules-nix-eval.md;
      process-safety = builtins.readFile ./_claude/rules-process-safety.md;
    };
  };
}
