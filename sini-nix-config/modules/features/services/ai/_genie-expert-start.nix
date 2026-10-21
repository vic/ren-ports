# genie-expert launcher: exports the credential token and starts claude in tmux (see genie-expert.nix).
{
  lib,
  inputs,
  pkgs,
}:
pkgs.writeShellScript "genie-expert-start" ''
  CLAUDE_CODE_OAUTH_TOKEN="$(< "$CREDENTIALS_DIRECTORY/claude-token")"
  export CLAUDE_CODE_OAUTH_TOKEN
  exec tmux -S "$RUNTIME_DIRECTORY/tmux.sock" new-session -d -s expert \
    ${lib.getExe inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code}
''
