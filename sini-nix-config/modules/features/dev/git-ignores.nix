# second file of dev-git: user setting field + global ignores.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
in
{
  # den settings.applications.dev.git.* -> user kind field (layout SETTINGS RULE).
  # extraIdentities was read with `or [ ]` in den but never declared; raw list of identity attrs.
  ren.kinds.user.dev-git = opt (t.submodule {
    options = {
      signing.method = opt (t.enum [
        "none"
        "ssh"
        "openpgp"
      ]) "none";
      extraIdentities = opt (t.listOf t.raw) [ ];
    };
  }) { };

  ren.aspects.dev-git.homeManager.programs.git.ignores = [
    ".direnv"
    "result"
    "result-*"
    "#*"
    ".git-bak*"
    "*~"
    "*.swp"
    ".DS_Store"
    "/.helix"
    ".flake"
    ".pkgs"
    ".aider*"
    "!.aider.conf.yml"
    "!.aiderignore"
    ".worktrees"
    ".pre-commit-config.yaml"
    ".claude"
  ];
}
