# addax helpers: pure fns every fleet file shares as `ren.helpers` (`addax = ren.helpers;`). No _module.args.
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  systemOf = pkgs: pkgs.stdenv.hostPlatform.system;
  index = builtins.fromJSON (builtins.readFile "${inputs.omniflake}/index.json");
  # one flake's per-system outputs projected to `system` (den `inputs'`)
  project =
    system: builtins.mapAttrs (_: v: if builtins.isAttrs v && v ? ${system} then v.${system} else v);
in
{
  ren.helpers = {
    # a file under secrets/, copied alone into the store (not the whole repo)
    secretsPath =
      path:
      builtins.path {
        path = inputs.self + "/secrets/${path}";
        name = baseNameOf path;
      };
    getExeName = pkg: baseNameOf (lib.getExe pkg);
    getExeName' = pkg: name: baseNameOf (lib.getExe' pkg name);
    compose = lib.flip lib.pipe;
    runIfCommandExists = cmd: command: ''
      if (which ${cmd} | is-not-empty) {
        ${command}
      }
    '';
    mkMergeShellCodeSep = lib.concatStringsSep "\n\n# ==========================\n";
    # omniflake's indexed flakes for the system of `pkgs`: `(addax.omni pkgs).unified.jjui.packages.default`
    omni =
      pkgs:
      lib.genAttrs [ "flakes" "pinned" "unified" ] (
        mode: builtins.mapAttrs (_: project (systemOf pkgs)) inputs.omniflake.${mode}
      );
    # flake url of an omniflake index pin (flake-file inputs on omniflake's revision)
    omniflakeUrl =
      name:
      let
        p = index.${name}.locked;
      in
      "${p.type}:${p.owner}/${p.repo}/${p.rev}";
    # this flake's packages for the system of `pkgs` (den `self'.packages`)
    selfPackages = pkgs: inputs.self.packages.${systemOf pkgs};
    usersOf = m: lib.listToAttrs (map (u: lib.nameValuePair u.name u) m.users);
  };
}
