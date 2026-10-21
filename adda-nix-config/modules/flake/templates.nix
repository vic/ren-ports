# templates: `nix flake init -t .#<name>` templates, the top-level flake output `templates`.
{ ren, ... }:
let
  templatesPath = ../../templates;
  bootstrap = {
    description = "A bootstrapping flake for creating a new host configuration.";
    path = "${templatesPath}/bootstrap";
  };
in
{
  ren.aspects.flake-templates = {
    at = ren.kinds.fleet;
    templates =
      { ... }:
      {
        inherit bootstrap;

        latex = {
          description = "A LaTeX environment for writing.";
          path = "${templatesPath}/latex";
        };

        vm-testing = {
          description = "A testing VM for quick ad-hoc testing of Nix configurations.";
          path = "${templatesPath}/vm-testing";
        };

        default = bootstrap;
      };
  };
}
