# writing-style: Unified suite for conventional commits, GitHub PR descriptions,
# non-obvious code comments, and KEP/RFC design docs.
{ ren, ... }:
{
  ren.aspects.dev-ai-skills-writing-style = {
    # These skills name other skills in their prose, so the reference has to be
    # structural rather than a hope that whoever enables writing-style also
    # enabled them (diagram, diagram-mermaid-render, calldiff).
    includes = with ren.aspects; [
      dev-ai-skills-diagram-design
      dev-ai-skills-diagram-mermaid-render
      dev-ai-tools-calldiff
    ];

    agent-extensions = {
      type = "skill";
      skills = {
        writing-commit-message = ./_assets/writing-commit-message;
        writing-pr-description = ./_assets/writing-pr-description;
        writing-code-comments = ./_assets/writing-code-comments;
        writing-doc-design = ./_assets/writing-doc-design;
        writing-doc-rfc = ./_assets/writing-doc-rfc;
        writing-tone = ./_assets/writing-tone;
      };
    };
  };
}
