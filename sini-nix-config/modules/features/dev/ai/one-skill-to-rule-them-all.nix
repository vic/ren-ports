# one-skill-to-rule-them-all (github:rebelytics/one-skill-to-rule-them-all): Task observer skill.
{ inputs, ... }:
{
  ren.aspects.dev-ai-skills-one-skill-to-rule-them-all = {
    flake-inputs.one-skill-to-rule-them-all = {
      url = "github:rebelytics/one-skill-to-rule-them-all";
      flake = false;
    };

    agent-extensions = {
      type = "skill";
      skills = {
        task-observer = inputs.one-skill-to-rule-them-all;
      };
    };
  };
}
