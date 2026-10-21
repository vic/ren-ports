# settings.permissions: allow / ask / deny lists.
{ ... }:
{
  ren.aspects.dev-ai-agents-claude.homeManager =
    { ... }:
    {
      programs.claude-code.settings.permissions = {
        allow = [
          # Edit(**) covers Write/MultiEdit/NotebookEdit; Read(**) covers Grep/Glob
          "Read(**)"
          "Edit(**)"
          "Grep(**)"
          "LS(**)"
          "WebSearch"
          "TodoRead(**)"
          "TodoWrite(**)"
          "Task(**)"

          # git (read-only)
          "Bash(git status *)"
          "Bash(git diff *)"
          "Bash(git log *)"
          "Bash(git show *)"
          "Bash(git blame *)"
          "Bash(git rev-parse *)"
          "Bash(git remote *)"
          "Bash(git branch:*)"

          # git (write). Subagents cannot establish user intent from a teammate
          # message, so these previously round-tripped through the orchestrator.
          # Push to `origin main` only: no wildcard remote, ref or flag, so a
          # force-push or a push to another branch still prompts. The `-C` and
          # `HEAD:main` forms are the ones worktree agents use (owner 2026-10-19).
          "Bash(git push origin main)"
          "Bash(git push origin HEAD:main)"
          "Bash(git -C * push origin main)"
          "Bash(git -C * push origin HEAD:main)"
          "Bash(git fetch *)"
          "Bash(git add *)"
          "Bash(git commit *)"

          # gates
          "Bash(treefmt *)"
          "Bash(just *)"

          # nix
          "Bash(nix eval *)"
          "Bash(nix flake *)"
          "Bash(nix build *)"
          "Bash(nix fmt)"
          "Bash(nix develop *)"

          # Read-only file operations
          "Bash(ls:*)"
          "Bash(cat:*)"
          "Bash(head:*)"
          "Bash(tail:*)"
          "Bash(grep:*)"
          "Bash(rg:*)"
          "Bash(fd:*)"
          "Bash(find:*)"
          "Bash(which:*)"
          "Bash(pwd)"
          "Bash(whoami)"
          "Bash(uname:*)"
          "Bash(wc *)"

          # view / search
          "Bash(rg *)"
          "Bash(jq *)"
          "Bash(yq *)"
          "Bash(sort *)"
          "Bash(journalctl *)"
        ];
      };
    };
}
