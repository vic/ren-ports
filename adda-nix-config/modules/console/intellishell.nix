# intellishell: intelli-shell and its hotkeys per shell
{ ren, ... }:
{
  ren.aspects.console-intellishell.homeManager = { config, lib, ... }: {
    programs.intelli-shell = {
      enable = true;
      # https://github.com/lasantosr/intelli-shell/blob/main/default_config.toml
      # https://lasantosr.github.io/intelli-shell/configuration/index.html
      settings = {
        check_updates = false;
        inline = false;
      };
      shellHotkeys = {
        variable_hotkey = "ctrl-h";
        search_hotkey = "ctrl-k";
      };
    };

    programs.nushell.environmentVariables = {
      INTELLI_VARIABLE_HOTKEY = "control char_h";
      INTELLI_SEARCH_HOTKEY = "control char_k";
      # bookmark_hotkey = "\\\\C-b";
      # fix_hotkey = "\\\\C-p";
      # skip_esc_bind = "\\\\C-q";
    };

    home.sessionVariables = {
      INTELLI_VARIABLE_HOTKEY = "ctrl-h";
      INTELLI_SEARCH_HOTKEY = "ctrl-k";

      INTELLI_STORAGE = "${config.home.homeDirectory}/synchronized/nextcloud/backup/intelli-shell/storage.db3";
    };

    # intelli-shell's fish integration binds its hotkeys with plain `bind`, which only applies to fish's vi "default"
    #  (command) mode. Since fish.nix enables fish_vi_key_bindings, typing happens in "insert" mode, where those
    #  hotkeys get shadowed by other plugins/tools with insert-mode-specific bindings on the same keys (e.g. autopair
    #  on ctrl-h, tirith on ctrl-j, fish_clipboard_copy on ctrl-x). Rebind the same hotkeys for insert mode too, after
    #  intelli-shell's own init.
    #
    # A one-shot rebind isn't enough: something (fish's own vi-mode first-prompt setup) calls `fish_user_key_bindings`
    #  once more after config.fish finishes, which re-triggers tirith's wrapped version and re-clobbers ctrl-j. So
    #  instead of rebinding once, chain into `fish_user_key_bindings` itself (the same pattern tirith uses) so our
    #  rebind reruns every time that function fires, always last.
    programs.fish.interactiveShellInit = lib.mkIf config.programs.intelli-shell.enableFishIntegration (
      lib.mkMerge [
        # When fish is launched as a child of the nushell login shell, it inherits nushell's exported
        #  __HM_SESS_VARS_SOURCED=1 from the process environment. Fish's own generated hm-session-vars.fish checks
        #  that very variable before (re)exporting INTELLI_SEARCH_HOTKEY/INTELLI_VARIABLE_HOTKEY, sees it already
        #  set, and no-ops -- so fish never gets to override nushell's own values for those two, which are set (in
        #  programs.nushell.environmentVariables above) using nushell's escape syntax ("control char_j"), not fish's
        #  ("ctrl-j"). intelli-shell's own `init fish` then fails to parse that as a keybinding. Force the
        #  fish-format values here, before anything else runs, so this holds regardless of what leaked in from the
        #  parent shell.
        (lib.mkBefore /* fish */ ''
          set -gx INTELLI_SEARCH_HOTKEY ${lib.escapeShellArg config.programs.intelli-shell.shellHotkeys.search_hotkey}
          set -gx INTELLI_VARIABLE_HOTKEY ${lib.escapeShellArg config.programs.intelli-shell.shellHotkeys.variable_hotkey}
        '')
        (lib.mkAfter /* fish */ ''
          function _intelli_shell_insert_bindings --description "Rebind IntelliShell hotkeys for fish's vi insert mode"
            set -l fish_major_version (string split . -- $version)[1]

            set -l search_key '-k nul'
            set -l bookmark_key \cb
            set -l variable_key \cl
            set -l fix_key \cx

            if test -n "$fish_major_version" -a "$fish_major_version" -ge 4
                set search_key ctrl-space
                set bookmark_key ctrl-b
                set variable_key ctrl-l
                set fix_key ctrl-x
            end

            if set -q INTELLI_SEARCH_HOTKEY; and test -n "$INTELLI_SEARCH_HOTKEY"
              set search_key $INTELLI_SEARCH_HOTKEY
            end
            if set -q INTELLI_BOOKMARK_HOTKEY; and test -n "$INTELLI_BOOKMARK_HOTKEY"
              set bookmark_key $INTELLI_BOOKMARK_HOTKEY
            end
            if set -q INTELLI_VARIABLE_HOTKEY; and test -n "$INTELLI_VARIABLE_HOTKEY"
              set variable_key $INTELLI_VARIABLE_HOTKEY
            end
            if set -q INTELLI_FIX_HOTKEY; and test -n "$INTELLI_FIX_HOTKEY"
              set fix_key $INTELLI_FIX_HOTKEY
            end

            if contains -- $search_key '\c@' '-k nul' 'ctrl-space'
                if test -n "$fish_major_version" -a "$fish_major_version" -ge 4
                    bind -M insert ctrl-space _intelli_search
                else
                    bind -M insert -k nul _intelli_search
                end
            else
              bind -M insert $search_key _intelli_search
            end
            bind -M insert $bookmark_key _intelli_save
            bind -M insert $variable_key _intelli_replace
            bind -M insert $fix_key _intelli_fix
          end

          if functions -q fish_user_key_bindings; and not functions -q _intelli_shell_original_fish_user_key_bindings
            functions -c fish_user_key_bindings _intelli_shell_original_fish_user_key_bindings
          end

          function fish_user_key_bindings
            if functions -q _intelli_shell_original_fish_user_key_bindings
              _intelli_shell_original_fish_user_key_bindings
            end
            _intelli_shell_insert_bindings
          end

          _intelli_shell_insert_bindings
        '')
      ]
    );
  };
}
