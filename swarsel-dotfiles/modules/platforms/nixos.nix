# NixOS: one system per host and variant; a guest forwards into the `guests` of its host (nixos-extra-modules).
{ ren, inputs, ... }:
let
  inherit (ren.lib) and not;
  sw = ren.helpers;
  # a host with its own nixpkgs (the sandbox fleet) builds in the sandbox branch
  sandboxed = and [
    ren.kinds.host
    (ren.lib.when (s: s.host.nixpkgs != null))
  ];
  metal = and [
    ren.kinds.host
    (not ren.kinds.guest)
    (not sandboxed)
    (not ren.kinds.export) # flake/exports.nix
  ];
in
{
  ren.helpers = { inherit metal sandboxed; };

  ren.classes.nixos = [
    {
      # old flake/modules.nix export (flake/exports.nix)
      at = ren.kinds.export;
      into = _: ms: { nixosModules.default.imports = ms; };
    }
    {
      # the sandbox fleet: forwarded in place to its own class (tests/sandbox.nix)
      at = sandboxed;
      into = _: ms: { nixos-sandbox.imports = ms; };
    }
    {
      at = metal;
      into =
        { host, variant, ... }:
        ms:
        let
          output = if variant.minimal then "nixosConfigurationsMinimal" else "nixosConfigurations";
        in
        {
          ${output}.${host.name} = inputs.nixpkgs.lib.nixosSystem {
            # the class lib: nixpkgs lib with `swarselsystems` and `hm` (overlay `modifications`)
            specialArgs.lib = host.system.legacyPackages.lib;
            modules = [
              inputs.disko.nixosModules.disko
              inputs.home-manager.nixosModules.home-manager
              inputs.microvm.nixosModules.host
              inputs.microvm.nixosModules.microvm
              inputs.nix-index-database.nixosModules.nix-index
              inputs.swarsel-nix.nixosModules.default
              (inputs.nixos-extra-modules + "/modules/guests")
              (inputs.nixos-extra-modules + "/modules/interface-naming.nix")
              (
                { lib, ... }:
                {
                  swarselsystems.mainUser = sw.mkStrong (sw.loginOf (builtins.head host.users));
                  microvm.guest.enable = lib.mkDefault false;
                  networking.hostName = sw.mkStrong host.name;
                  node = {
                    arch = lib.mkForce host.system.name;
                    configDir = sw.configDirOf host;
                    lockFromBootstrapping = lib.mkIf (!variant.minimal) (sw.mkStrong true);
                    name = lib.mkForce host.name;
                    secretsDir = sw.secretsDirOf host;
                    type = lib.mkForce "nixos";
                  };
                }
              )
            ]
            ++ ms;
          };
        };
    }
    {
      # old confLib.mkMicrovm: the guest's modules run inside its host's `guests.<name>`
      at = ren.kinds.guest;
      into =
        { guest, globals-defs, ... }:
        ms: {
          nixos = { config, lib, ... }: {
            guests = lib.mkIf config.swarselsystems.withMicroVMs (
              sw.mkMicrovm {
                inherit
                  config
                  lib
                  guest
                  ms
                  ;
                globals = sw.globalsOf globals-defs;
              }
            );
          };
        };
    }
  ];
}
