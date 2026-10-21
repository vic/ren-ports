# generated .gitignore (files class, fleet-level).
{ ren, ... }:
{
  ren.aspects.docs-gitignore = {
    at = ren.fleet.sini;
    files =
      { pkgs, ... }:
      {
        files.files = [{ path_ = ".gitignore"; drv = pkgs.writeText ".gitignore" ''
      /result
      /result.*
      .direnv
      .cache
      .claude
      CLAUDE.md
      docs/superpowers/
      .pre-commit-config.yaml
      /.panix
    ''; }];
      };
  };
}
