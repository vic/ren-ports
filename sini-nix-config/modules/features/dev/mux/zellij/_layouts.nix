# Zellij theme + layouts built from the stylix-or-fallback palette.
statusbar: colors: {
  # TODO: Remove stylix dependency from zellij, make optional
  stylixTheme = ''
    themes {
      stylix {
        bg "#${colors.base01}"
        fg "#${colors.base05}"
        red "#${colors.base08}"
        green "#${colors.base0E}"
        blue "#${colors.base0D}"
        yellow "#${colors.base0A}"
        magenta "#${colors.base0E}"
        orange "#${colors.base09}"
        cyan "#${colors.base0C}"
        black "#${colors.base00}"
        white "#${colors.base07}"
      }
    }
  '';

  layoutDev = ''
    layout {
        tab name="code" focus=true {
            pane {
                command "nvim"
                args "."
            }
        }

        tab name="exec" {
            pane split_direction="vertical" {
                pane {
                    name "main"
                }
            }
        }

        tab name="ai" {
            pane {
                name "ai-assistant"
                command "fish"
                args "-c" "if command -sq pi; pi; else; echo 'gsesh/zellij: pi not found on PATH'; exec fish; end"
            }
        }

        ${statusbar}
    }
  '';

  layoutDefault = ''
    layout {
        ${statusbar}

        tab {
            pane
        }
    }
  '';
}
