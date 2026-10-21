# shells: the shell set plus zoxide and vivid
{ ren, ... }:
{
  ren.aspects.shells.includes = with ren.aspects; [
    shells-aliasesAbbreviations
    shells-scripts
    shells-carapace
    shells-starship
    shells-bash
    shells-fish
    shells-zsh
    shells-dash
    # shells-xonsh
    shells-nushell
  ];

  ren.aspects.shells.homeManager = { config, ... }: {
    home.shell.enableShellIntegration = true;

    home.sessionVariables = {
      "NIXPKGS_ALLOW_UNFREE" = 1;
      "SHELL" = "${config.home.profileDirectory}/bin/nu";
    };

    programs.zoxide = {
      enable = true;
      options = [
        # "--no-cmd" # Do not create 'zi' and 'z' command aliases.
      ];
    };
    home.sessionVariables._ZO_ECHO = 1; # Enable zoxide echoing the directory it is changing to.

    programs.vivid = {
      enable = true;
      activeTheme = "molokai";
      # filetypes = lib.readFile (
      #   builtins.fetchurl {
      #     url = "https://github.com/sharkdp/vivid/blob/master/config/filetypes.yml";
      #     sha256 = "sha256:0lzsdc2v5f0bif52fz0w92mapachywkkdbfc6kqvkj9gbg3wz6m1";
      #   }
      # );
    };
  };
}
