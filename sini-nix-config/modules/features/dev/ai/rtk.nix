# rtk (github:rtk-ai/rtk): CLI proxy compressing dev-command output; binary + skill + PreToolUse hook.
{ inputs, ... }:
{
  ren.aspects.dev-ai-tools-rtk.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.rtk ];

      programs.claude-code = {
        skills.rtk = ./_rtk;

        # Rewrites eligible Bash commands to rtk equivalents; rtk must be on PATH.
        settings.hooks.PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "rtk hook claude";
              }
            ];
          }
        ];
      };
    };
}
