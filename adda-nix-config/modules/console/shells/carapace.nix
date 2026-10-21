# carapace: multi-shell completions
{ ren, ... }:
{
  ren.aspects.shells-carapace.homeManager =
    { lib, pkgs, ... }:
    let
      carapaceBridges = [
        "argcomplete"
        "bash"
        "carapace"
        "carapace-bin"
        "clap"
        "click"
        "cobra"
        "complete"
        "fish"
        "inshellisense"
        "kingpin"
        "macro"
        "powershell"
        "urfavecli"
        "yargs"
        "zsh"
        "fzf"
      ];
      carapaceBridgesStr = lib.concatStringsSep "," carapaceBridges;
    in

    {
      programs.carapace = {
        enable = true;

        # Bridged completers must be on carapace's own PATH, not just the user's.
        extraPackages = with pkgs; [
          carapace-bridge
        ];

        environment = {
          CARAPACE_BRIDGES = carapaceBridgesStr;
          # CARAPACE_ENV = true;
          CARAPACE_MATCH = true;
          CARAPACE_NOSPACE = "*";
          # CARAPACE_MERGEFLAGS = false;
          CARAPACE_UNFILTERED = true;
        };
      };

      programs.nushell = {
        extraConfig = lib.mkMerge [
          # nu
          ''
            mkdir ($nu.cache-dir)
            touch ($nu.cache-dir | path join "carapace.nu")
          ''
        ];
      };
    };
}
