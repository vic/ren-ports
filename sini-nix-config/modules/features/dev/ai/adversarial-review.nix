# adversarial-review: Independent multi-perspective critic review loop for spec,
# architecture, and code verification.
{ ... }:
{
  ren.aspects.dev-ai-skills-adversarial-review.agent-extensions = {
    type = "skill";
    skills.adversarial-review = ./_assets/adversarial-review;
  };
}
