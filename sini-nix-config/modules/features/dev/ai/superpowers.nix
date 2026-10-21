# superpowers: ported from den skills/superpowers.nix (pcvelz/superpowers).
{ inputs, ... }:
{
  ren.aspects.dev-ai-skills-superpowers = {
    flake-inputs.superpowers-extended-cc = {
      url = "github:pcvelz/superpowers";
      flake = false;
    };

    agent-extensions = {
      type = "plugin";
      marketplace = {
        name = "superpowers-extended-cc-marketplace";
        src = inputs.superpowers-extended-cc;
        pluginId = "superpowers-extended-cc@superpowers-extended-cc-marketplace";
      };
      skills = {
        superpowers = inputs.superpowers-extended-cc;
      };
    };
  };
}
