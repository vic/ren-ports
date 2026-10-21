# inputs: every flake input of flake.nix, emitted into the `flake-inputs` channel (flake-file.nix writes them).
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  # The build itself: Ren, the module loader, flake-file, nixpkgs and home-manager.
  ren.aspects.flake-core = {
    at = ren.system.x86_64-linux;
    flake-inputs =
      { ... }:
      {
        ren.url = "github:vic/ren";
        import-tree.url = "github:denful/import-tree";
        # flake-file takes omniflake's index revision (addax.omniflakeUrl); home-manager is pinned to a literal revision.
        flake-file.url = addax.omniflakeUrl "flake-file";
        nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

        # nixpkgs-stable.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";
        # nixpkgs-local.url = "path:/home/adda/documents/it/nixos/nixpkgs";

        #determinate = {
        #  url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
        #  inputs = {
        #    nixpkgs.follows = "nixpkgs";
        #    nix.inputs = {
        #      git-hooks-nix.follows = "git-hooks-nix";
        #      # nixpkgs.follows = "nixpkgs";
        #    };
        #  };
        #};
        # hjem.follows = "hjem-rum/hjem";
        # hjem = {
        #   url = "github:feel-co/hjem";
        #   inputs.nixpkgs.follows = "nixpkgs";
        # };
        # hjem-rum = {
        #   url = "github:snugnug/hjem-rum";
        #   inputs.nixpkgs.follows = "nixpkgs";
        #   # inputs.hjem.follows = "hjem";
        # };

        home-manager = {
          url = "github:nix-community/home-manager/640725978b99076e18e069f6e7d2959124584f8f";
          inputs.nixpkgs.follows = "nixpkgs";
        };

        # systems.url = "github:nix-systems/x86_64-linux";
      };
  };

  # Inputs other lanes' aspects read. One aspect declares them so the consumers stay free of flake wiring.
  ren.aspects.flake-consumer-inputs = {
    at = ren.system.x86_64-linux;
    flake-inputs =
      { ... }:
      {
        # consumer: modules/hardware/cpu-power.nix (cpuPower = auto-cpufreq)
        auto-cpufreq = {
          # omniflake's index pins this rev with a narHash this nix does not reproduce (NAR hash mismatch)
          url = "github:AdnanHodzic/auto-cpufreq/35d8015afc1bc2c4b30526828dddde4c53925976";
          inputs.nixpkgs.follows = "nixpkgs";
        };
        # consumer: every `inputs.omniflake.unified.*` (modules/helpers.nix `omni`, `omniflakeUrl`)
        # omniflake's own flake-parts is the foundation substituted into indexed flakes; its stale `nixpkgs-lib`
        #  lacks newer `lib.licenses` (e.g. `valveSDK`, needed by rimsort).
        flake-parts = {
          url = "github:hercules-ci/flake-parts";
          inputs.nixpkgs-lib.follows = "nixpkgs";
        };
        omniflake = {
          url = "github:fzakaria/omniflake";
          # url = "github:Adda0/omniflake/add-flakes";
          inputs = {
            # omniflake's own flake-parts is the foundation substituted into indexed flakes; its stale `nixpkgs-lib`
            #  lacks newer `lib.licenses` (e.g. `valveSDK`, needed by rimsort).
            flake-parts.follows = "flake-parts";
            nixpkgs.follows = "nixpkgs";
          };
        };
        # consumer: the xremap aspect (old aspects/xremap.nix)
        xremap = {
          url = "github:xremap/nix-flake";
          inputs = {
            nixpkgs.follows = "nixpkgs";
            flake-parts.follows = "flake-parts";
          };
        };
        # consumer: the nushell aspect (old aspects/console/shells/nushell.nix)
        nu_scripts = {
          url = "github:nushell/nu_scripts";
          flake = false;
        };
        # consumer: the claude aspect (old aspects/ai/claude.nix)
        plannotator = {
          url = "github:backnotprop/plannotator";
          flake = false;
        };
        tuicr = {
          url = "github:agavra/tuicr";
          flake = false;
        };
        # consumer: the games aspect (old aspects/desktop/games.nix)
        rimstack = {
          url = "github:TheForgotten69/RimStack";
          flake = false;
        };
      };
  };
}
