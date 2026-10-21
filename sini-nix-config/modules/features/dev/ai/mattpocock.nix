# mattpocock: ported from den skills/mattpocock.nix (mattpocock/skills).
{ inputs, ... }:
{
  ren.aspects.dev-ai-skills-mattpocock = {
    flake-inputs.mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };

    agent-extensions = {
      type = "plugin";
      marketplace = {
        name = "mattpocock";
        src = inputs.mattpocock-skills;
        pluginId = "mattpocock-skills@mattpocock";
      };
      skills = {
        mattpocock = inputs.mattpocock-skills;
      };
    };
  };
}
