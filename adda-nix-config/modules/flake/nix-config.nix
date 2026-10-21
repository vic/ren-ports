# nix-config: the flake's nixConfig (flake-specific substituters and options, not the system configuration).
{ ren, ... }:
{
  ren.aspects.flake-nix-config = {
    at = ren.system.x86_64-linux;
    flake-file.flake-file.nixConfig = {
      allow-import-from-derivation = true;
      # Flake-specific substituters and trusted-public-keys, not affecting the system configuration.
      extra-substituters = [
        # Nix community cache server.
        "https://nix-community.cachix.org"
        # Flox cache server.
        "https://cache.flox.dev"
        # Numtide cache server.
        "https://numtide.cachix.org"
        "https://cache.numtide.com"
        # devenv and cachix cache servers (old languages/nix.nix)
        "https://devenv.cachix.org https://cachix.cachix.org"
        # Helix unstable cache server (old editors/helix.nix).
        "https://helix.cachix.org"
      ];
      extra-trusted-public-keys = [
        # Nix community cache server public key.
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # Flox cache server public key.
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
        # Numtide cache server public key.
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE"
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
        # Helix unstable cache server public key.
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      ];
      submodules = true;
      lazy-trees = true;
      accept-flake-config = true;
      auto-optimise-store = true;
      use-xdg-base-directories = true;
      show-trace = true;
    };
  };
}
