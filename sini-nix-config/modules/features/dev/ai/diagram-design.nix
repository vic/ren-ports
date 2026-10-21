# diagram-design: ported from den skills/diagram-design.nix (cathrynlavery/diagram-design).
{ inputs, ... }:
{
  ren.aspects.dev-ai-skills-diagram-design = {
    flake-inputs.diagram-design = {
      url = "github:cathrynlavery/diagram-design";
      flake = false;
    };

    agent-extensions = {
      type = "plugin";
      marketplace = {
        name = "diagram-design";
        src = inputs.diagram-design;
        pluginId = "diagram-design@diagram-design";
      };
      skills = {
        diagram-design = inputs.diagram-design;
      };
    };
  };
}
