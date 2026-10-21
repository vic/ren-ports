# fleet: the root scope. It holds the repository secrets that every machine and every channel reads.
{
  ren,
  lib,
  inputs,
  ...
}:
let
  inherit (ren.lib) opt;
  inherit (ren.helpers) importEncrypted;
  t = lib.types;
  args = {
    inherit inputs;
    inherit (inputs.nixpkgs) lib;
    inherit (inputs.topologyPrivate) topologyPrivate;
  };
in
{
  ren.kinds.fleet = {
    below = [
      ren.kinds.system
      ren.kinds.variant
    ];
    # repo.secrets.common: PII that is not a secret after deployment (see secrets/repo)
    pii = opt t.raw { };
    # the static globals module (old repoSecrets globals; sandbox: its own file)
    globalsFile = t.raw;
    # true when secrets/repo is the plain demo set of hosts/utility/hotel/secrets
    isDemo = opt t.bool false;
  };

  ren.fleet.swarsel = {
    pii = importEncrypted inputs.repoSecrets.pii args;
    isDemo = inputs.repoSecrets.isDemo or false;
    globalsFile = inputs.repoSecrets.globals;
  };
  # old tests/sandbox.nix: vacanthouse is its own world (nixpkgs-sandbox, its own globals)
  ren.fleet.sandbox = {
    pii = importEncrypted inputs.repoSecrets.pii args; # old repo.secrets.common: the same file
    globalsFile = inputs.self + "/hosts/utility/vacanthouse/secrets/globals.nix";
  };
  ren.kinds.fleet.spawns.system = s: if s.fleet.name == "swarsel" then ren.system else { };
}
