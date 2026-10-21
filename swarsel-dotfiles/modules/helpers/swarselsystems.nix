# helpers: the old `lib.swarselsystems` functions, shared by all files as `sw = ren.helpers;`.
{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  systems = import inputs.systems;
in
{
  ren.helpers = {
    cidrToSubnetMask =
      cidr:
      let
        prefixLength = lib.toInt (lib.last (lib.splitString "/" cidr));
        bits = lib.genList (i: if i < prefixLength then 1 else 0) 32;
        octets = lib.genList (
          i: lib.foldl (acc: bit: acc * 2 + bit) 0 (lib.sublist (i * 8) 8 bits)
        ) 4;
      in
      lib.concatStringsSep "." (map toString octets);
    darwinSystems = builtins.filter (lib.hasSuffix "-darwin") systems;
    linuxSystems = builtins.filter (lib.hasSuffix "-linux") systems;
    getBaseDomain =
      domain:
      let
        domainParts = builtins.filter (x: builtins.isString x && x != "") (builtins.split "\\." domain);
      in
      if builtins.length domainParts > 0 then
        builtins.concatStringsSep "." (builtins.tail domainParts)
      else
        "";
    getSubDomain =
      domain:
      let
        domainParts = builtins.filter (x: builtins.isString x && x != "") (builtins.split "\\." domain);
      in
      if builtins.length domainParts > 0 then builtins.head domainParts else "";
    mkIfElse =
      p: yes: no:
      if p then yes else no;
    mkIfElseList =
      p: yes: no:
      lib.mkMerge [
        (lib.mkIf p yes)
        (lib.mkIf (!p) no)
      ];
    mkStrong = lib.mkOverride 60;
    # the package names of a pkgs/ dir (pkgs/flake/default.nix, pkgs/config/default.nix)
    readNix =
      type:
      lib.filter (name: name != "default.nix" && name != "optional" && name != "darwin") (
        lib.attrNames (builtins.readDir "${inputs.self}/${type}")
      );
    mkTrueOption = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    # a repository file as its own store path (old `root`, a specialArg)
    root =
      subpath:
      builtins.path {
        name = builtins.baseNameOf subpath;
        path = "${inputs.self}/${subpath}";
      };
    toCapitalized =
      str:
      if builtins.stringLength str == 0 then
        ""
      else
        lib.toUpper (builtins.substring 0 1 str)
        + lib.toLower (builtins.substring 1 (builtins.stringLength str - 1) str);
  };
}
