# haskell: GHC tooling, ghci config and editor wiring.
{ ren, ... }:
{
  ren.aspects.languages-haskell = {
    homeManager =
      { pkgs, ... }:
      {
        home.file.".ghc/ghci.conf" = {
          text = ''
            :set prompt "\ESC[1;32m\x03BB> \ESC[m"
            :set prompt-cont "\ESC[1;32m > \ESC[m"

            :seti -XGADTSyntax
            :seti -XGeneralizedNewtypeDeriving
            :seti -XInstanceSigs
            :seti -XLambdaCase
            :seti -XPartialTypeSignatures
            :seti -XScopedTypeVariables
            :seti -XTypeApplications
            :seti -XOverloadedStrings
            :seti -XNumericUnderscores
            :seti -XNoMonomorphismRestriction
            :seti -XQuasiQuotes

            :set +s +t +m
            :set -fdefer-type-errors -Wall
          '';
        };

        home.packages = with pkgs; [
          hlint
          stylish-haskell
          # haskellPackages.brittany # FIXME: Broken.
          # haskellPackages.hls-brittany-plugin
          haskellPackages.haskell-language-server
          ormolu
          fourmolu
          haskellPackages.hindent
          ghcid
        ];
      };

    helixLanguages = {
      language = [
        {
          name = "haskell";
          auto-format = true;
          formatter = {
            command = "fourmolu";
          };
          language-servers = [
            "haskell-language-server"
          ];
        }
      ];
    };

    # helixExtraPackages =
    #   # { pkgs, ... }:
    #   # [
    #   # {
    #   #   packages = extraPackages;
    #   # }
    #   # pkgs.cowsay
    #   extraPackages
    # # ]
    # #
    # ;
    # zedEditorExtraPackages = extraPackages;
    zed-extensions = { ... }: [ "haskell" ];
  };
}
