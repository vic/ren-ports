# zed-editor: Zed editor base config (contributions arrive via zedSettings/zedPackages classes and the zed-extensions channel).
{ ren, ... }:
{
  ren.aspects.editors-zed-editor.homeManager =
    {
      lib,
      pkgs,
      user,
      zed-extensions,
      ...
    }:
    {
      programs.zed-editor = {
        enable = true;
        package = pkgs.zed-editor-fhs;

        extraPackages = with pkgs; [
          ruff
        ];

        # Zed settings.
        # For information on how to configure Zed, see the Zed documentation: https://zed.dev/docs/configuring-zed.
        # To see all of Zed's default settings without changing your custom settings, run `zed: open default settings`
        #  from the command palette (cmd-shift-p / ctrl-shift-p).
        userSettings = {
          which_key = {
            delay_ms = 0;
            enabled = true;
          };

          show_signature_help_after_edits = true;
          auto_signature_help = false;
          mouse_wheel_zoom = true;

          calls = {
            mute_on_join = true;
          };
          git = {
            inline_blame = {
              show_commit_summary = true;
            };
          };
          git_panel = {
            show_count_badge = true;
            sort_by_path = false;
            file_icons = true;
            tree_view = true;
          };
          terminal = {
            toolbar = {
              breadcrumbs = true;
            };
            default_height = 320.0;
            default_width = 640.0;
            copy_on_select = true;
            show_count_badge = true;
            # line_height = "standard";
          };
          project_panel = {
            sort_order = "default";
            sort_mode = "directories_first";
            hide_hidden = false;
            hide_root = true;
            git_status_indicator = true;
            diagnostic_badges = true;
            scrollbar = {
              show = "auto";
            };
            bold_folder_labels = true;
            indent_size = 15.0;
            entry_spacing = "standard";
            hide_gitignore = true;
            dock = "left";
          };
          window_decorations = "client";
          bottom_dock_layout = "full";
          preview_tabs = {
            enable_keep_preview_on_code_navigation = true;
            enable_preview_multibuffer_from_code_navigation = true;
            enable_preview_from_file_finder = true;
          };
          tab_bar = {
            show_pinned_tabs_in_separate_row = false;
          };
          tabs = {
            show_close_button = "hover";
            show_diagnostics = "all";
            file_icons = true;
            git_status = true;
          };
          title_bar = {
            button_layout = "platform_default";
            show_menus = true;
            show_branch_status_icon = true;
          };
          status_bar = {
            show_active_file = true;
            line_endings_button = true;
          };
          close_on_file_delete = true;
          search = {
            center_on_match = true;
            regex = true;
          };
          use_smartcase_search = true;
          diagnostics = {
            inline = {
              enabled = true;
            };
          };
          document_folding_ranges = "off";
          semantic_tokens = "combined";
          colorize_brackets = true;
          code_lens = "on";
          vim = {
            toggle_relative_line_numbers = false;
          };
          outline_panel = {
            indent_size = 15.0;
            dock = "right";
          };
          collaboration_panel = {
            button = false;
            dock = "left";
          };
          toolbar = {
            code_actions = true;
          };
          preferred_line_length = 120;

          # Type annotations etc.
          inlay_hints = {
            enabled = true;
            show_background = false;
          };

          base_keymap = "JetBrains";
          rounded_selection = true;
          agent_ui_font_size = 14.0;
          ui_font_family = ".ZedMono";
          buffer_line_height = {
            custom = 1.5;
          };
          icon_theme = {
            mode = "system";
            light = "Material Icon Theme";
            dark = "Material Icon Theme";
          };
          auto_update = false;
          session = {
            trust_all_worktrees = true;
          };
          formatter = "auto";
          cli_default_open_behavior = "new_window";
          autosave = "on_focus_change";
          buffer_font_size = 14.0;
          current_line_highlight = "all";
          cursor_blink = false;
          tab_size = 4;
          ensure_final_newline_on_save = true;
          format_on_save = "on";
          remove_trailing_whitespace_on_save = true;
          show_whitespaces = "all";
          soft_wrap = "editor_width";
          show_wrap_guides = true;
          indent_guides = {
            background_coloring = "disabled";
            active_line_width = 7;
            line_width = 3;
            coloring = "indent_aware";
          };
          wrap_guides = user.editors.verticalRulerGuides;
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
          theme = {
            dark = "Ayu Dark";
            light = "Ayu Light";
            mode = "system";
          };
          ui_font_size = 16.0;
          vertical_scroll_margin = user.editors.verticalScrollMarginAroundCursor;

          # LLMs.
          agent = {
            show_turn_stats = true;
            use_modifier_to_send = true;
            single_file_review = true;
            sidebar_side = "right";
            dock = "right";
            default_model = {
              provider = "copilot_chat";
              model = "claude-haiku-4.5";
            };
            favorite_models = [
              {
                provider = "copilot_chat";
                model = "claude-haiku-4.5";
                enable_thinking = true;
              }
            ];
          };
          edit_predictions.provider = "copilot";

          # Modes.
          vim_mode = false;
          helix_mode = true;

          # lsp.rust-analyzer = {
          #   initialization_options = {
          #     checkOnSave = {
          #       command = "clippy";
          #     };
          #   };
          # };
        };

        userKeymaps = [
          {
            context = "Editor && vim_mode == insert && !menu";
            bindings = {
              "j j" = "vim::NormalBefore";
            };
          }
          {
            # Claude Code (and other TUIs) read ESC CR as "insert newline"
            # rather than "submit". This is what `claude`'s `/terminal-setup`
            # writes for Zed's keymap.
            context = "Terminal";
            bindings = {
              "shift-enter" = [
                "terminal::SendText"
                (
                  let
                    esc = builtins.fromJSON ''"\u001b"'';
                  in
                  "${esc}\r"
                )
              ];
            };
          }
        ];

        # https://github.com/zed-industries/extensions/tree/main/extensions
        # Language-specific extensions are contributed by their respective aspects via the
        # `zed-extensions` channel (e.g. modules/languages/*.nix).
        extensions = lib.flatten zed-extensions ++ [
          "colored-zed-icons-theme"
          "colorizer"
          "csharp"
          "csv"
          "docker-compose"
          "dockerfile"
          "editorconfig"
          "env"
          "fish"
          "git-firefly"
          "html"
          "ini"
          "just"
          "log"
          "make"
          "material-icon-theme"
          "mermaid"
          "nu"
          "rainbow-csv"
          "toml"
          "typos"
          "typst"
          "xml"
        ];
      };
    };
}
