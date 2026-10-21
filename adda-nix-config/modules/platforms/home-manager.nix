# home-manager: each user of a host gets a home inside the host's nixos (useGlobalPkgs), plus shell alias classes.
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within has;
  inHost = and [
    ren.kinds.user
    (within ren.kinds.host)
  ];
  # a class whose content is one attrset written into hm option paths (den `forward` batteries)
  intoHm =
    paths:
    { ... }:
    ms: {
      homeManager =
        # deadnix: skip -- pkgs must be named so flatten can pass it to content
        { lib, pkgs, ... }@a:
        let
          v = ren.lib.flatten a ms;
        in
        lib.mkMerge (map (p: lib.setAttrByPath p v) paths);
    };
in
{
  ren.classes.homeManager = {
    at = inHost;
    into = { user, ... }: ms: { nixos.home-manager.users.${user.name}.imports = ms; };
  };

  ren.helpers.intoHm = intoHm;
  ren.classes.aliases = {
    at = inHost;
    into = intoHm [
      [
        "home"
        "shellAliases"
      ]
    ];
  };
  ren.classes.abbreviations = {
    at = inHost;
    into = intoHm [
      [
        "programs"
        "fish"
        "shellAbbrs"
      ]
      [
        "programs"
        "nushell"
        "environmentVariables"
        "config"
        "abbreviations"
      ]
      [
        "programs"
        "zsh"
        "zsh-abbr"
        "abbreviations"
      ]
    ];
  };

  ren.aspects.home-manager-nixos = {
    at = and [
      ren.kinds.host
      (has ren.kinds.user)
    ];
    nixos.imports = [ inputs.home-manager.nixosModules.home-manager ];
  };
}
