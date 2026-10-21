# vscodium: VSCodium base config (contributions arrive via vscodiumSettings class and the vscodium-extensions channel).
{ ren, inputs, ... }:
{
  # `flake-file.inputs` of the old file dropped (see report).
  ren.aspects.editors-vscodium = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        user,
        vscodium-extensions,
        ...
      }:
      {
        programs.vscodium = {
          enable = true;
          profiles.default = {
            globalSnippets = {
              fixme = {
                body = [
                  "$LINE_COMMENT FIXME: $0"
                ];
                description = "Insert a FIXME remark";
                prefix = [
                  "fixme"
                ];
              };
              todo = {
                body = [
                  "$LINE_COMMENT TODO: $0"
                ];
                description = "Insert a TODO remark";
                prefix = [
                  "todo"
                ];
              };
              note = {
                body = [
                  "$LINE_COMMENT NOTE: $0"
                ];
                description = "Insert a NOTE remark";
                prefix = [
                  "note"
                ];
              };
            };
            userSettings = {
              chat = {
                disableAIFeatures = false;
                viewSessions.orientation = "stacked";
              };
              explorer.confirmDragAndDrop = false;
              files = {
                insertFinalNewline = true;
                trimFinalNewlines = true;
                trimTrailingWhitespace = true;
                eol = "\n";
                autoSave = "afterDelay";
              };
              terminal.integrated = {
                cursorStyle = "line";
                cursorBlinking = "solid";
                copyOnSelection = true;
                defaultProfile.linux = "fish"; # or "zsh", "bash", etc.
              };
              editor = {
                lineNumbers = "relative";

                largeFileOptimizations = false;
                renderWhitespace = "all";
                rulers = user.editors.verticalRulerGuides;
                renderLineHighlight = "all";
                minimap.enabled = false;
                cursorBlinking = "solid";
                cursorSurroundingLines = user.editors.verticalScrollMarginAroundCursor;
                cursorSurroundingLinesStyle = "all";
                linkedEditing = true;
                fontFamily = "Mononoki Nerd Font Mono";
                fontSize = 14;
                guides.bracketPairs = "active";
                bracketPairColorization.enabled = true;
                autoClosingBrackets = "beforeWhitespace";
                wordWrap = "on";
                multiCursorModifier = "ctrlCmd";
              };
              "indenticator.inner.showHighlight" = true;
              telemetry.telemetryLevel = "off";

              # override VSCode keycodes with system keycodes
              keyboard.dispatch = "keyCode";

              html.format.wrapLineLength = 120;
              security.workspace.trust.enabled = false;
              vim = {
                useCtrlKeys = true;
                useSystemClipboard = true;
                enableNeovim = true;
              };
              workbench = {
                list.automaticKeyboardNavigation = false;
                colorCustomizations = {
                  editorRuler.foreground = "#333333";
                  editor.lineHighlightBackground = "#0f0f0f";
                };
              };
              todo-tree = {
                general.tags = [
                  "BUG"
                  "HACK"
                  "FIXME"
                  "TODO"
                  "XXX"
                  "[ ]"
                  "[x]"
                ];
                regex.regex = "(//|#|<!--|;|/\\*|^|^\\s*(-|\\d+.))\\s*($TAGS)";
              };
              search.seedWithNearestWord = true;
              notebook.lineNumbers = "on";
              redhat.telemetry.enabled = false;
              typescript.updateImportsOnFileMove.enabled = "always";
              auto-close-tag = {
                SublimeText3Mode = true;
                insertSpaceBeforeSelfClosingTag = true;
              };
              javascript.updateImportsOnFileMove.enabled = "always";
              git.ignoreLimitWarning = true;
              hediet.vscode-drawio.theme = "Kennedy";
              go.toolsManagement.autoUpdate = true;
              prolog.executable = "/usr/bin/swipl";
              rust-analyzer.check.command = "clippy";
              haskell.manageHLS = "GHCup";
              python.languageServer = "Pylance";
              window.zoomLevel = 2;
              "extensions.experimental.affinity" = {
                "asvetliakov.vscode-neovim" = 1;
              };
              "[html]" = {
                "editor.defaultFormatter" = "esbenp.prettier-vscode";
              };
              "[rust]" = {
                editor.formatOnSave = true;
              };
            };
            keybindings = [
              {
                key = "ctrl+h";
                command = "workbench.action.navigateLeft";
              }
              {
                key = "ctrl+l";
                command = "workbench.action.navigateRight";
              }
              {
                key = "ctrl+k";
                command = "workbench.action.navigateUp";
              }
              {
                key = "ctrl+j";
                command = "workbench.action.navigateDown";
              }
              {
                key = "alt+a";
                command = "github.copilot.acceptCursorPanelSolution";
                when = "github.copilot.activated && github.copilot.panelVisible && activeWebviewPanelId == 'GitHub Copilot Suggestions'";
              }
              {
                key = "ctrl+/";
                command = "-github.copilot.acceptCursorPanelSolution";
                when = "github.copilot.activated && github.copilot.panelVisible && activeWebviewPanelId == 'GitHub Copilot Suggestions'";
              }
              {
                key = "ctrl+shift+t";
                command = "television.ToggleTextFinder";
              }
              {
                key = "ctrl+shift+f";
                command = "television.ToggleFileFinder";
              }
              {
                key = "ctrl+shift+s";
                command = "television.ToggleTextFinderWithSelection";
              }
              {
                # Claude Code (and other TUIs) read this bracketed-paste-wrapped
                # newline as "insert newline" rather than "submit". This is what
                # `claude`'s `/terminal-setup` writes for VS Code-family terminals.
                key = "shift+enter";
                command = "workbench.action.terminal.sendSequence";
                args.text =
                  let
                    esc = builtins.fromJSON ''"\u001b"'';
                  in
                  "${esc}[200~\n${esc}[201~";
                when = "terminalFocus && terminalHasBeenCreated";
              }
            ];
            enableExtensionUpdateCheck = false;
            enableUpdateCheck = false;
            extensions =
              let
                inherit (pkgs.nix4vscode)
                  # forVscode
                  # forVscodeVersion
                  # forVscodePrerelease
                  # forVscodeVersionPrerelease

                  # forOpenVsx
                  # forOpenVsxVersion
                  # forOpenVsxPrerelease
                  # forOpenVsxVersionPrerelease

                  # forVscodeExt
                  forVscodeExtVersion
                  # forVscodeExtPrerelease
                  # forVscodeExtVersionPrerelease

                  # forOpenVsxExt
                  # forOpenVsxExtVersion
                  # forOpenVsxExtPrerelease
                  # forOpenVsxExtVersionPrerelease
                  ;

                decorators = {
                  "ms-vscode.cpptools" = {
                    buildTools = with pkgs; [
                      clang-tools
                    ];
                  };
                  "rust-lang.rust-analyzer" =
                    { pkgs, ... }:
                    {
                      buildInputs = with pkgs; [
                        rust-analyzer
                      ];
                    };
                };
              in
              # forVscodeExt decorators [
              # ] ++
              forVscodeExtVersion decorators config.programs.vscode.package.version (
                (lib.flatten vscodium-extensions)
                ++ [
                  "github.copilot-chat"

                  # "zhuangtongfa.material-theme"
                  # Using the specified version
                  # "editorconfig.editorconfig.0.9.4"

                  # vscode-extensions.visualjj.visualjj
                  "soaibuzzaman.smt-z3"

                  # vscode-marketplace.ms-vscode-remote.remote-containers"
                  # vscode-marketplace.ms-vscode-remote.vscode-remote-extensionpack"
                  "ms-vscode.makefile-tools"
                  "github.vscode-pull-request-github"
                  "christian-kohler.path-intellisense"
                  "aaron-bond.better-comments"
                  "vadimcn.vscode-lldb"
                  "vscodevim.vim"
                  # vscode-marketplace.jasew.vscode-helix-emulation"
                  "jeff-hykin.better-syntax"
                  # open-vsx.jeff-hykin.better-syntax"
                  "usernamehw.errorlens" # Inline highlighting of errors, warnings and other language diagnostics.
                  "gruntfuggly.todo-tree"
                  "alefragnani.project-manager"
                  "jgclark.vscode-todo-highlight"
                  "formulahendry.code-runner"
                  "tamasfe.even-better-toml"
                  "timonwong.shellcheck"
                  # vscode-marketplace.rioj7.commandOnAllFiles"
                  # vscode-marketplace.robole.file-bunny"
                  "alexpasmantier.television"
                  "editorconfig.editorconfig"
                  "ocamllabs.ocaml-platform"
                ]
              )
            # ++ forVscodeVersion "1.100.2" [
            #   "vadimcn.vscode-lldb"
            # ]
            # ++ forVscodePrerelease [
            #   "ms-toolsai.vscode-jupyter-slideshow"
            #   "ms-dotnettools.csdevkit"
            # ]
            # ++ forVscodeVersionPrerelease "1.100.2" [
            #   "ms-toolsai.vscode-jupyter-cell-tags"
            #   "ms-dotnettools.csharp"
            # ]
            # ++ forVscode [
            #   "ms-vscode.cpptools"
            # ]
            # ++ forVscodeExtPrerelease myDecorators [
            #   "matepek.vscode-catch2-test-adapter"
            # ]
            # ++ forVscodeExtVersionPrerelease myDecorators "1.100.2" [
            #   "ms-azuretools.vscode-containers"
            # ]
            # ++ forOpenVsx [
            #   "jnoortheen.nix-ide"
            # ]
            # ++ forOpenVsxVersion "1.100.2" [
            #   "ms-ceintl.vscode-language-pack-zh-hans"
            # ]
            # ++ forOpenVsxPrerelease [
            #   "Dart-Code.flutter"
            # ]
            # ++ forOpenVsxVersionPrerelease "1.100.2" [
            #   "Continue.continue"
            # ]
            # ++ forVscodeExtVersion myDecorators "1.100.2" [
            #   "ms-python.python"
            # ]
            # ++ forOpenVsxExt myDecorators [
            #   "redhat.java"
            # ]
            # ++ forOpenVsxExtVersion myDecorators "1.100.2" [
            #   "charliermarsh.ruff"
            # ]
            # ++ forOpenVsxExtPrerelease myDecorators [
            #   "svelte.svelte-vscode"
            # ]
            # ++ forOpenVsxExtVersionPrerelease myDecorators "1.100.2" [
            #   "posit.shiny"
            # ]
            ;

            # extensions =
            # let
            #   nix-vscode-extensions = inputs'.nix-vscode-extensions.extensions;
            # in
            # # with pkgs;
            # #     # with extensions.forVSCodeVersion "${pkgs.vscodium-fhs.version}";
            # with nix-vscode-extensions;
            # [
            #   # open-vsx
            #   vscode-marketplace.github.copilot
            #   vscode-marketplace-release.github.copilot-chat
            #   #     vscode-marketplace.ms-python.python
            #   #     # vscode-marketplace.ms-vscode-remote.remote-containers
            #   #     # vscode-marketplace.ms-vscode-remote.vscode-remote-extensionpack
            #   #     vscode-marketplace.ms-python.debugpy
            #   #     vscode-marketplace.ms-toolsai.jupyter
            #   #     # vscode-marketplace.harttrav.markdown-jupytext
            #   #     vscode-marketplace.ms-vscode.makefile-tools
            #   #     vscode-marketplace.james-yu.latex-workshop
            #   #     vscode-marketplace.github.vscode-pull-request-github
            #   #     vscode-marketplace.christian-kohler.path-intellisense
            #   #     vscode-marketplace.yzhang.markdown-all-in-one
            #   #     vscode-marketplace.aaron-bond.better-comments
            #   # vscode-marketplace.vadimcn.vscode-lldb

            #   #       vscode-marketplace.vscodevim.vim
            #   #       # vscode-marketplace.jasew.vscode-helix-emulation

            #   #       vscode-marketplace.llvm-vs-code-extensions.vscode-clangd
            #   #       # vscode-marketplace.mkhl.direnv
            #   #       open-vsx.mkhl.direnv

            #   #       vscode-marketplace.jeff-hykin.better-syntax
            #   #       # open-vsx.jeff-hykin.better-syntax
            #   #       vscode-marketplace.bbenoist.nix
            #   #       # vscode-marketplace.arrterian.nix-env-selector
            #   #       open-vsx.arrterian.nix-env-selector
            #   #       vscode-marketplace.jnoortheen.nix-ide
            #   #       vscode-marketplace.b4dm4n.nixpkgs-fmt
            #   #       # vscode-marketplace.brettm12345.nixfmt-vscode
            #   #       vscode-marketplace.usernamehw.errorlens
            #   #       vscode-marketplace.gruntfuggly.todo-tree
            #   #       vscode-marketplace.alefragnani.project-manager
            #   #       vscode-marketplace.jgclark.vscode-todo-highlight
            #   #       vscode-marketplace.formulahendry.code-runner
            #   #       vscode-marketplace.tamasfe.even-better-toml
            #   #       vscode-extensions.visualjj.visualjj
            #   #       vscode-marketplace.timonwong.shellcheck
            #   #       open-vsx.soaibuzzaman.smt-z3
            #   #       # vscode-marketplace.rioj7.commandOnAllFiles
            #   #       # vscode-marketplace.robole.file-bunny
            #   #       vscode-marketplace.alexpasmantier.television
            #   #       vscode-marketplace.editorconfig.editorconfig
            # ];
          };
        };
      };

    # Overlay emission; the host applies it (old: nixos nixpkgs.overlays).
    overlays =
      { ... }:
      # let
      #   nixVscodeExtensions = final: _: {
      #     nix-vscode-extensions = import inputs.nixpkgs {
      #       inherit (final.stdenv.hostPlatform) system;
      #       inherit (final) config;
      #       overlays = [
      #         inputs.nix-vscode-extensions.overlays.default
      #       ];
      #     };
      #   };
      #   nix4Vscode = final: _: {
      #     nix4Vscode = import inputs.nixpkgs {
      #       inherit (final.stdenv.hostPlatform) system;
      #       inherit (final) config;
      #       overlays = [
      #         inputs.nix4vscode.overlays.default
      #       ];
      #     };
      #   };
      # in
      # inputs.nix-vscode-extensions.overlays.default
      # nixVscodeExtensions
      inputs.omniflake.unified.nix4vscode.overlays.default
    # nix4Vscode
    ;
  };
}
