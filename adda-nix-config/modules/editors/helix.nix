# helix: Helix editor base config (language/package contributions arrive via helixSettings/helixLanguages/helixPackages classes).
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.editors-helix = {
    homeManager =
      {
        # config,
        pkgs,
        user,
        ...
      }:
      let
        inherit (addax) getExeName getExeName';
        # inherit (lib) getExe;
      in
      {
        programs.helix = {
          enable = true;
          defaultEditor = true;
          package = (addax.omni pkgs).pinned.helix.packages.helix;
          ignores = user.editors.ignoredFilePatterns;
          # settings = lib.importTOML ../../dotfiles/home/.config/helix/config.toml;
          settings = {
            theme = "dark_plus"; # "adwaita-dark", "dark_plus", ""papercolor-dark
            editor = {
              line-number = "relative";
              mouse = true;
              scrolloff = 10;
              cursorline = true;
              cursorcolumn = true;
              gutters = [
                "diagnostics"
                "spacer"
                "line-numbers"
                "spacer"
                "diff"
              ];
              auto-save = true;
              rulers = user.editors.verticalRulerGuides;
              bufferline = "always";
              color-modes = true;
              text-width = 120;

              statusline = {
                left = [
                  "mode"
                  "spinner"
                  "version-control"
                ];
                center = [
                  "file-name"
                  "file-modification-indicator"
                ];
                right = [
                  "diagnostics"
                  "workspace-diagnostics"
                  "selections"
                  "primary-selection-length"
                  "position"
                  "position-percentage"
                  "total-line-numbers"
                  "file-encoding"
                  "file-line-ending"
                  "file-type"
                ];
                separator = "│";
                mode.normal = "NORMAL";
                mode.insert = "INSERT";
                mode.select = "SELECT";
              };
              cursor-shape = {
                insert = "bar";
                normal = "block";
                select = "block";
              };

              file-picker = {
                hidden = false;
              };

              lsp = {
                display-messages = true;
                display-inlay-hints = true;
              };

              auto-pairs = {
                "(" = ")";
                "{" = "}";
                "[" = "]";
                "\"" = "\"";
                "`" = "`";
                #""<"" = "">"";
              };

              whitespace = {
                # render = "all";
                # or control each character
                render = {
                  space = "all";
                  tab = "all";
                  nbsp = "all";
                  newline = "all";
                };
                characters = {
                  space = "·";
                  nbsp = "⍽";
                  tab = "→";
                  newline = "⏎";
                  tabpad = "·"; # Tabs will look like "→···" (depending on tab width)
                };
              };

              indent-guides = {
                render = true;
                character = "╎"; # Some characters that work well: "▏", "┆", "┊", "⸽"
                skip-levels = 1;
              };

              completion-replace = true;
              completion-trigger-len = 0;

              smart-tab.supersede-menu = true;

              soft-wrap = {
                enable = true;
                max-wrap = 20; # increase value to reduce forced mid-word wrapping
                max-indent-retain = 0;
                # wrap-indicator = "";  # set wrap-indicator to "" to hide it
                wrap-at-text-width = false;
              };

              # Minimum severity to show a diagnostic after the end of a line.
              end-of-line-diagnostics = "hint";

              inline-diagnostics = {
                # Minimum severity to show a diagnostic on the primary cursor's line.
                # Note that `cursor-line` diagnostics are hidden in insert mode.
                cursor-line = "hint";
                # Minimum severity to show a diagnostic on other lines:
                # other-lines = "hint";
              };
            };

            keys = {
              normal = {
                "esc" = [
                  "keep_primary_selection"
                  "collapse_selection"
                ];
                space = {
                  e = [
                    ":sh rm -f /tmp/files2open"
                    ":set mouse false"
                    ":insert-output yazi \"%{buffer_name}\" --chooser-file=/tmp/files2open"
                    ":redraw"
                    ":set mouse true"
                    ":open /tmp/files2open"
                    "select_all"
                    "split_selection_on_newline"
                    "goto_file"
                    ":buffer-close! /tmp/files2open"
                  ];
                };
              };
            };
          };

          # languages = lib.importTOML ../../dotfiles/home/.config/helix/languages.toml;
          languages = {
            language = [
              {
                name = "html";
                language-servers = [
                  (getExeName pkgs.vale-ls)
                  (getExeName' pkgs.vscode-langservers-extracted "vscode-html-language-server")
                ];
              }
            ];

            language-server = {
              typos-lsp = {
                command = getExeName pkgs.typos-lsp;
              };
            };
          };
        };
      };

    abbreviations =
      { pkgs, ... }:
      let
        inherit (addax) getExeName;
      in
      with pkgs;
      {
        h = "${getExeName helix}";
        j = "${getExeName helix}";
      };
  };
}
