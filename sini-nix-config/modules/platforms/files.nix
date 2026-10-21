# files class: fleet-level generated repo files (README, LICENSE, .gitignore, .sops.yaml) -> fileModules.
{ ren, ... }:
{
  ren.classes.files = {
    at = ren.kinds.fleet;
    into = _: ms: { fileModules = ms; };
  };
}
