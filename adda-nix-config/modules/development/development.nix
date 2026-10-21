# development: desktop and console developer tooling (meld, editorconfig, flatpak apps, make/just abbreviations).
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.development-desktop = {
    os = {
      services.flatpak.packages = [
        "me.iepure.devtoolbox"
        "de.leopoldluley.Clapgrep"
      ];
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          (meld.overrideAttrs (oldAttrs: {
            patches = (oldAttrs.patches or [ ]) ++ [ ./0001-Increse-maximal-line-length.patch ];
          }))
          markuplinkchecker
          kdePackages.kompare
          kdiff3
          jc
        ];
      };
  };

  ren.aspects.development-console = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          flatpak-builder
          typos
          typos-lsp
        ];

        editorconfig = {
          enable = true;
          settings = {
            # https://editorconfig.org
            "*" = {
              charset = "utf-8";
              end_of_line = "lf";
              trim_trailing_whitespace = true;
              insert_final_newline = true;
              max_line_width = 120;
              indent_style = "space";
              indent_size = 4;
            };
            "*.{md,toml,ya?ml,nix,html,css,tex}" = {
              indent_size = 2;
            };
            "{Makefile,**/CMakeLists.txt}" = {
              indent_style = "tab";
            };
          };
        };

        programs.jqp.enable = true;
      };

    abbreviations =
      { pkgs, ... }:
      let
        inherit (addax) getExeName;
      in
      with pkgs;
      {
        m = getExeName gnumake;
        mk = getExeName gnumake;
        js = "${getExeName just}";
        k = "${getExeName just}";
      };
  };
}
