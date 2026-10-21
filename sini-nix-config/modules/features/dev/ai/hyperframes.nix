# hyperframes (github:heygen-com/hyperframes): HTML video composition framework
# for AI coding agents, with the `hyperframes` CLI, FFmpeg and Node.js.
{ inputs, ... }:
{
  ren.aspects.dev-ai-skills-hyperframes = {
    flake-inputs.hyperframes = {
      url = "github:heygen-com/hyperframes";
      flake = false;
    };

    agent-extensions =
      { lib, ... }:
      {
        type = "plugin";
        marketplace = {
          name = "hyperframes";
          src = inputs.hyperframes;
          pluginId = "hyperframes@hyperframes";
        };
        skills = {
          hyperframes = "${inputs.hyperframes}/skills/hyperframes";
        }
        // lib.mapAttrs' (name: _: lib.nameValuePair name "${inputs.hyperframes}/skills/${name}") (
          lib.filterAttrs (
            name: type: type == "directory" && builtins.pathExists "${inputs.hyperframes}/skills/${name}/SKILL.md"
          ) (builtins.readDir "${inputs.hyperframes}/skills")
        );
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.local.hyperframes
          pkgs.ffmpeg-headless.bin
          pkgs.nodejs_22
        ];
        programs.claude-code.settings.permissions.allow = [
          "Bash(hyperframes *)"
          "Bash(hyperframes-localize-fonts *)"
        ];
        programs.git.ignores = [ ".hyperframes/" ];
      };
  };
}
