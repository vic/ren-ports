# caveman: ported from den skills/caveman.nix (JuliusBrussee/caveman).
{ inputs, ... }:
{
  ren.aspects.dev-ai-skills-caveman = {
    flake-inputs.caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };

    agent-extensions = {
      type = "plugin";
      marketplace = {
        name = "caveman";
        src = inputs.caveman;
        pluginId = "caveman@caveman";
      };
      skills = {
        caveman = inputs.caveman;
      };
    };
  };
}
