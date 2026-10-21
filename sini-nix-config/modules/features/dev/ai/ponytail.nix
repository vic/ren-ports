# ponytail: ported from den skills/ponytail.nix (dietrichgebert/ponytail).
{ inputs, ... }:
{
  ren.aspects.dev-ai-skills-ponytail = {
    flake-inputs.ponytail = {
      url = "github:dietrichgebert/ponytail";
      flake = false;
    };

    agent-extensions = {
      type = "plugin";
      marketplace = {
        name = "ponytail";
        src = inputs.ponytail;
        pluginId = "ponytail@ponytail";
      };
      skills = {
        ponytail = inputs.ponytail;
      };
    };
  };
}
