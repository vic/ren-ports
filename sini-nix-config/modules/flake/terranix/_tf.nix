# One terranix configuration the way the terranix flake-module (flake-module.nix:100-250) exposes it:
# { terraformConfiguration, terraformWrapper, scripts, app }. `configuration` overrides the built config.tf.json.
{ inputs }:
{
  pkgs,
  name,
  modules ? [ ],
  workdir ? name,
  tofu ? pkgs.opentofu,
  configuration ? inputs.terranix.lib.terranixConfiguration { inherit pkgs modules; },
}:
let
  terraformConfiguration = configuration;
  terraformWrapper = pkgs.writeShellApplication {
    name = tofu.meta.mainProgram;
    runtimeInputs = [ tofu ];
    text = ''
      mkdir -p ${workdir}
      cd ${workdir}
      ${tofu.meta.mainProgram} "$@"
    '';
  };
  bin = terraformWrapper.meta.mainProgram;
  mkScript =
    scriptName: text:
    pkgs.writeShellApplication {
      name = scriptName;
      runtimeInputs = [ terraformWrapper ];
      text = ''
        mkdir -p ${workdir}
        ln -sf ${terraformConfiguration} ${workdir}/config.tf.json
        ${text}
      '';
    };
  scripts = {
    init = mkScript "init" "${bin} init";
    apply = mkScript "apply" ''
      ${bin} init
      ${bin} apply
    '';
    plan = mkScript "plan" ''
      ${bin} init
      ${bin} plan
    '';
    destroy = mkScript "destroy" ''
      ${bin} init
      ${bin} destroy
    '';
  };
in
{
  inherit terraformConfiguration terraformWrapper scripts;
  # `nix build .#<name>` is the apply script; the others hang off it as passthru
  app = scripts.apply.overrideAttrs {
    inherit name;
    passthru = scripts // {
      config = terraformConfiguration;
      terraform = terraformWrapper;
    };
  };
}
