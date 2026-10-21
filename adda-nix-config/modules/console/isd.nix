# isd: systemd TUI config
{ ren, ... }:
{
  ren.aspects.console.homeManager =
    { pkgs, ... }:
    {
      xdg.configFile."isd/config.yaml".source = pkgs.writers.writeYAML "config.yaml" {
        # yaml-language-server: $schema=schema.json
        # ^ This links to the JSON Schema that provides auto-completion support
        #   and dynamically checks the input. For this to work, your editor must have
        #   support for the `yaml-language-server`
        #   - <https://github.com/redhat-developer/yaml-language-server>
        #
        #   Check the `Clients` section for more information:
        #   - <https://github.com/redhat-developer/yaml-language-server?tab=readme-ov-file#clients>
        #
        # To create a fresh `config.yaml` file with the defaults,
        # simply delete this file. It will be re-created when `isd` starts.

        # The systemctl startup mode (`user`/`system`).
        # By default loads the mode from the last session (`auto`).
        startup_mode = "auto";

        # Auto refresh the preview unit _and_ unit states of selected units.
        # Example: When a selected unit changes from running to failed
        # the unit state color and preview window will be updated after this
        # time has passed, even if _nothing_ is pressed.
        preview_and_selection_refresh_interval_sec = 3;

        # Auto refresh all unit states.
        # This is important to find new units that have been added
        # since the start of `isd`.
        # Please note that low values will cause many and large systemctl calls.
        full_refresh_interval_sec = 15;

        # Cache the unit search text input across restarts.
        # Enabled by default.
        cache_input = true;

        # Seconds to wait before computing state updates (default 0.05s).
        # For example, time after input has changed before updating the selection.
        # Or time to wait to update preview window after highlighting new value.
        # The idea is to minimize the number of 'irrelvant' updated during fast
        # scrolling through the unit list or quick typing.
        updates_throttle_sec = 0.05;

        # Editor to use; Default = `auto`
        # Defaults to the first editor defined in one of the environment variables:
        # - $SYSTEMD_EDITOR, $EDITOR, $VISUAL
        # and then falls back to the first available editor:
        # - `editor`, `nano`, `vim`, `vi`.
        editor = "auto";

        # Default pager to open preview tabs in (except for `Journal`). Default = `auto`
        # Defaults to the first pager defined in one of the environment variables:
        # - `SYSTEMD_PAGER`, `PAGER`
        # and then falls back to the first available pager:
        # - `less`, `more`.
        #
        # Note: Input is always provided via STDIN to the pager!
        default_pager = "auto";

        # Default pager to open preview for `Journal` tab. Default = `auto`
        # Defaults to the first pager defined in one of the environment variables:
        # - `SYSTEMD_PAGER`, `PAGER`
        # and then falls back to the first available pager:
        # - `less`, `more`.
        #
        # Note: Input is always provided via STDIN to the pager!
        journal_pager = "lnav";

        # Default arguments for `journalctl` to generate the
        # output of the `Journal` preview window.
        journalctl_args = [
          "--catalog"
        ];

        # The theme of the application.
        theme = "textual-dark";

        # Configurable keybindings for common actions.
        # The actions (keys) are predefined and the configured keybindings
        # are given as values.
        #
        # Note about keybindings:
        # Multiple keys can be defined by separating them with a comma `,`.
        # Please note that depending on the terminal, terminal multiplexer, and
        # operating system supported keys will vary and may require trial and error.
        # See: <https://posting.sh/guide/keymap/#key-format>
        generic_keybindings = {
          # Next preview tab
          next_preview_tab = "l,right";
          # Previous preview tab
          previous_preview_tab = "h,left";
          # Clear search input.
          clear_input = "ctrl+backspace";
          # Copy highlighted unit path to the clipboard
          copy_unit_path = "ctrl+y";
          # Open in pager
          open_preview_in_pager = "enter";
          # Open in editor
          open_preview_in_editor = "alt+enter";
          # Toggle mode
          toggle_mode = "ctrl+m";
          # Open `config.yaml` file with `editor`.
          # Creates `config.yaml` if it doesn't exist.
          open_config = "alt+o";
        };
        # Configurable keybindings for the selection window.
        selection_keybindings = {
          # Down
          down = "down,j";
          # Up
          up = "up,k";
          # Toggle selection.
          toggle_selection = "space";
          # Page down
          page_down = "ctrl+down,pagedown";
          # Page up
          page_up = "ctrl+up,pageup";
          # First Element
          first = "home";
          # Last Element
          last = "end";
        };

        # Configurable keybindings for preview log windows.
        preview_keybindings = {
          # Scroll down
          scroll_down = "down,j";
          # Scroll up
          scroll_up = "up,k";
          # Scroll right
          scroll_right = "right,l";
          # Scroll left
          scroll_left = "left,h";
          # Page down
          scroll_page_down = "ctrl+down,pagedown";
          # Page up
          scroll_page_up = "ctrl+up,pageup";
          # Page left
          scroll_page_left = "ctrl+left";
          # Page right
          scroll_page_right = "ctrl+right";
          # First Page
          scroll_top = "home";
          # Last Page
          scroll_end = "end";
        };

        # List of configurable systemctl subcommands.
        # The exact subcommand (including arguments) can be defined
        # by settings `command`. The keybinding(s) that triggers this
        # systemctl subcommand is configured via the `keybinding` key.
        # The description is used to describe the subcommand
        # and used in the applications command palette to find
        # the action.
        #
        # Note about keybindings:
        # Multiple keys can be defined by separating them with a comma `,`.
        # Please note that depending on the terminal, terminal multiplexer, and
        # operating system supported keys will vary and may require trial and error.
        # See: <https://posting.sh/guide/keymap/#key-format>
        systemctl_commands = [
          {
            keybinding = "ctrl+e";
            command = "edit";
            description = "systemctl edit";
          }
          {
            keybinding = "alt+e";
            command = "edit --runtime";
            description = "systemctl edit --runtime";
          }
          {

            keybinding = "ctrl+o";
            command = "stop";
            description = "systemctl stop";
          }
          {

            keybinding = "ctrl+a";
            command = "start";
            description = "systemctl start";
          }
          {

            keybinding = "ctrl+l";
            command = "reload";
            description = "systemctl reload";
          }
          {

            keybinding = "ctrl+n";
            command = "enable";
            description = "systemctl enable";
          }
          {

            keybinding = "ctrl+r";
            command = "restart";
            description = "systemctl restart";
          }
          {

            keybinding = "ctrl+k";
            command = "mask";
            description = "systemctl mask";
          }
          {
            keybinding = "ctrl+u";
            command = "unmask";
            description = "systemctl unmask";
          }
        ];

        # Arguments passed to the configured `default_pager`.
        # Should NOT be required most of the time.
        # As for most pagers, the correct arguments/environment variables are set by default
        # if this value is unset (`null`).
        default_pager_args = null;

        # Arguments passed to the configured `journal_pager`.
        # Should NOT be required most of the time.
        # As for most pagers, the correct arguments/environment variables are set by default
        # if this value is unset (`null`).
        journal_pager_args = null;

        # How many lines to show in the preview windows.
        # Setting this value too large, especially with long journal entries
        # will considerably slow down the application.
        # Usually the default should be left as is.
        #
        # Note: The output is not trimmed when a pager or editor is opened!
        preview_max_lines = 500;
      };
    };
}
