# Users: one instance per login name; identity and per-user editor/AI data (den user opt.*).
{ ren, lib, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
  vcsT = t.submodule {
    options.authorName = opt t.str "David Chocholatý";
    options.email = opt t.str "chocholaty.david@protonmail.com";
    options.githubTokenSops = opt t.raw (ren.helpers.secretsPath "gh.yaml"); # sops yaml with key `token`
  };
  editorsT = t.submodule {
    options.ignoredFilePatterns = opt (t.listOf t.str) [
      ".build/"
      ".claude/"
      ".devenv/"
      ".direnv/"
      ".git/"
      ".idea/"
      ".jj/"
      "*~"
      "*.swp"
      "build/"
      "flake.lock"
      "node_modules/"
    ];
    options.verticalRulerGuides = opt (t.listOf t.int) [
      80
      120
    ];
    options.verticalScrollMarginAroundCursor = opt t.int 10;
  };
  ruleT = t.submodule {
    options.description = lib.mkOption { type = t.str; };
    options.text = lib.mkOption { type = t.str; };
  };
in
{
  ren.kinds.user = {
    description = t.str;
    nick = t.str;
    realName = t.str;
    vcs = opt vcsT { };
    editors = opt editorsT { };
    aiRules = opt (t.attrsOf ruleT) { }; # ~/.config/claude/rules/<n>.md and ~/.omp/agent/rules/<n>.md
    authorizedKeys = opt (t.listOf t.str) [ ];
  };
}
