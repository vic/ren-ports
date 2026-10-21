# ui-ux-pro-max: ported from den skills/ui-ux-pro-max.nix (nextlevelbuilder/ui-ux-pro-max-skill).
{ inputs, ... }:
{
  ren.aspects.dev-ai-skills-ui-ux-pro-max = {
    flake-inputs.ui-ux-pro-max-skill = {
      url = "github:nextlevelbuilder/ui-ux-pro-max-skill";
      flake = false;
    };

    agent-extensions = {
      type = "plugin";
      marketplace = {
        name = "ui-ux-pro-max-skill";
        src = inputs.ui-ux-pro-max-skill;
        pluginId = "ui-ux-pro-max@ui-ux-pro-max-skill";
      };
      skills = {
        ui-ux-pro-max = inputs.ui-ux-pro-max-skill;
      };
    };
  };
}
