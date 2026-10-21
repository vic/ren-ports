# gstack (github:garrytan/gstack): Garry Tan's suite of autonomous workflow skills
# for AI coding agents. Automatically discovers sub-skills and provides bun runtime.
{ inputs, ... }:
{
  ren.aspects.dev-ai-skills-gstack = {
    flake-inputs.gstack = {
      url = "github:garrytan/gstack";
      flake = false;
    };

    agent-extensions =
      { lib, ... }:
      {
        type = "skill";
        skills = {
          gstack = inputs.gstack;
        }
        // lib.mapAttrs' (name: _: lib.nameValuePair name "${inputs.gstack}/${name}") (
          lib.filterAttrs (
            name: type: type == "directory" && builtins.pathExists "${inputs.gstack}/${name}/SKILL.md"
          ) (builtins.readDir inputs.gstack)
        );
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.bun ];
        programs.claude-code.settings.permissions.allow = [
          "Bash(bun run *)"
          "Bash(bun *)"
          "Bash(~/.claude/skills/*)"
        ];
        programs.git.ignores = [ ".gstack/" ];
      };
  };
}
