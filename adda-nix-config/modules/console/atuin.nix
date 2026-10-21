# atuin: shell history with the nushell integration patched
{ ren, ... }:
{
  ren.aspects.console-atuin.homeManager =
    {
      lib,
      ...
    }:
    {
      # home-manager's default nushell integration just sources the raw
      # `atuin init nu` output, which names both the ctrl-r and up-arrow
      # keybindings "atuin". Nushell validates $env.config as soon as the
      # second one is appended (inside atuin's own script), so renaming them
      # afterwards in a later extraConfig block is too late to silence the
      # "shared_keybindings_name" warning. Patch the duplicate name at build
      # time instead and source that.
      programs.atuin.enableNushellIntegration = false;

      programs.nushell.extraConfig =
        lib.mkOrder 2000 # Load after fzf so Atuin keeps Ctrl-R in Nushell.
          ''
            # Source this in your ~/.config/nushell/config.nu
            # minimum supported version = 0.93.0
            module compat {
              export def --wrapped "random uuid -v 7" [...rest] { atuin uuid }
            }
            use (if not (
                (version).major > 0 or
                (version).minor >= 103
            ) { "compat" }) *

            if 'ATUIN_SESSION' not-in $env or ('ATUIN_SHLVL' not-in $env) or ($env.ATUIN_SHLVL != ($env.SHLVL? | default "")) {
                $env.ATUIN_SESSION = (random uuid -v 7 | str replace -a "-" "")
                $env.ATUIN_SHLVL = ($env.SHLVL? | default "")
            }
            hide-env -i ATUIN_HISTORY_ID

            def _atuin_osc133_command_executed [] {
                if 'ATUIN_PTY_PROXY_ACTIVE' not-in $env {
                    return
                }
                if 'ATUIN_HISTORY_ID' not-in $env or ($env.ATUIN_HISTORY_ID | is-empty) {
                    return
                }

                print -n $"(char -u '1b')]133;C(char bel)"
            }

            def _atuin_osc133_command_finished [exit_code: int] {
                if 'ATUIN_PTY_PROXY_ACTIVE' not-in $env {
                    return
                }
                if 'ATUIN_HISTORY_ID' not-in $env or ($env.ATUIN_HISTORY_ID | is-empty) {
                    return
                }

                print -n $"(char -u '1b')]133;D;($exit_code);history_id=($env.ATUIN_HISTORY_ID);session_id=($env.ATUIN_SESSION)(char bel)"
            }

            # Magic token to make sure we don't record commands run by keybindings
            let ATUIN_KEYBINDING_TOKEN = $"# (random uuid)"

            let _atuin_pre_execution = {||
                if ($nu | get history-enabled?) == false {
                    return
                }
                let cmd = (commandline)
                if ($cmd | is-empty) {
                    return
                }
                if not ($cmd | str starts-with $ATUIN_KEYBINDING_TOKEN) {
                    $env.ATUIN_HISTORY_ID = (with-env { ATUIN_SHELL: nu } {
                        atuin history start --hook -- $cmd | complete | get stdout | str trim
                    })
                    _atuin_osc133_command_executed
                }
            }

            let _atuin_pre_prompt = {||
                let last_exit = $env.LAST_EXIT_CODE
                if 'ATUIN_HISTORY_ID' not-in $env {
                    return
                }
                _atuin_osc133_command_finished $last_exit
                if (version).minor >= 104 or (version).major > 0 {
                    job spawn {
                        ^atuin history end --hook $'--exit=($env.LAST_EXIT_CODE)' -- $env.ATUIN_HISTORY_ID | complete
                    } | ignore
                } else {
                    do { atuin history end --hook $'--exit=($last_exit)' -- $env.ATUIN_HISTORY_ID } | complete
                }
                hide-env -i ATUIN_HISTORY_ID
            }

            def _atuin_search_cmd [...flags: string] {
                if (version).minor >= 106 or (version).major > 0 {
                    [
                        $ATUIN_KEYBINDING_TOKEN,
                        ([
                            `with-env { ATUIN_QUERY: (commandline), ATUIN_SHELL: nu } {`,
                                ([
                                    'let output = (run-external atuin search',
                                    ($flags | append [--interactive] | each {|e| $'"($e)"'}),
                                    'e>| str trim)',
                                ] | flatten | str join ' '),
                                'if ($output | str starts-with "__atuin_accept__:") {',
                                'commandline edit --accept ($output | str replace "__atuin_accept__:" "")',
                                '} else {',
                                'commandline edit $output',
                                '}',
                            `}`,
                        ] | flatten | str join "\n"),
                    ]
                } else {
                    [
                        $ATUIN_KEYBINDING_TOKEN,
                        ([
                            `with-env { ATUIN_QUERY: (commandline) } {`,
                                'commandline edit',
                                '(run-external atuin search',
                                    ($flags | append [--interactive] | each {|e| $'"($e)"'}),
                                ' e>| str trim)',
                            `}`,
                        ] | flatten | str join ' '),
                    ]
                } | str join "\n"
            }

            $env.config = ($env | default {} config).config
            $env.config = ($env.config | default {} hooks)
            $env.config = (
                $env.config | upsert hooks (
                    $env.config.hooks
                    | upsert pre_execution (
                        $env.config.hooks | get pre_execution? | default [] | append $_atuin_pre_execution)
                    | upsert pre_prompt (
                        $env.config.hooks | get pre_prompt? | default [] | append $_atuin_pre_prompt)
                )
            )

            $env.config = ($env.config | default [] keybindings)

            def _atuin_helix_edit_modes_if_supported [modes: list<string> = [helix_normal, helix_insert]] {
                if ((version).major > 0 or (version).minor >= 115) { $modes } else { [] }
            }

            if (version).minor >= 104 or (version).major > 0 {
                with-env { ATUIN_SHELL: nu } {
                    job spawn {
                        atuin __internal prepare-search-index | complete
                    } | ignore
                }
            }
            $env.config = (
                $env.config | upsert keybindings (
                    $env.config.keybindings
                    | append {
                        name: atuin
                        modifier: control
                        keycode: char_r
                        mode: ([emacs, vi_normal, vi_insert] | append (_atuin_helix_edit_modes_if_supported))
                        event: { send: executehostcommand cmd: (_atuin_search_cmd) }
                    }
                )
            )
            $env.config = (
                $env.config | upsert keybindings (
                    $env.config.keybindings
                    | append {
                        name: atuin_up_arrow
                        modifier: none
                        keycode: up
                        mode: ([emacs, vi_normal, vi_insert] | append (_atuin_helix_edit_modes_if_supported))
                        event: {
                            until: [
                                {send: menuup}
                                {send: executehostcommand cmd: (_atuin_search_cmd '--shell-up-key-binding') }
                            ]
                        }
                    }
                )
            )

            $env.config.hinter.closure = {|ctx|
              if ($ctx.line | str length) == 0 {
                null
              } else {
                let candidate = (try {
                  ^atuin search --cwd $ctx.cwd --limit 1 --search-mode prefix --cmd-only $ctx.line
                  | lines
                  | first
                } catch {
                  null
                })

                if $candidate == null or not ($candidate | str starts-with $ctx.line) {
                  null
                } else {
                  ($candidate | str substring (($ctx.line | str length))..)
                }
              }
            }
          '';

      programs.atuin = {
        enable = true;
        daemon = {
          enable = true;
        };
        #flags = [ "--disable-up-arrow" ];
        settings = {
          search.shells = "all";
          ai = {
            enable = true;
            opening = {
              send_cwd = true;
              send_last_command = true;
            };
          };

          # where to store your database, default is your system data directory
          # linux/mac: ~/.local/share/atuin/history.db
          # windows: %USERPROFILE%/.local/share/atuin/history.db
          # db_path = "~/.history.db";

          # where to store your encryption key, default is your system data directory
          # linux/mac: ~/.local/share/atuin/key
          # windows: %USERPROFILE%/.local/share/atuin/key
          # key_path = "~/.key";

          # where to store your auth session token, default is your system data directory
          # linux/mac: ~/.local/share/atuin/session
          # windows: %USERPROFILE%/.local/share/atuin/session
          # session_path = "~/.session";

          # date format used, either "us" or "uk"
          # dialect = "us";

          # default timezone to use when displaying time
          # either "l", "local" to use the system's current local timezone, or an offset
          # from UTC in the format of "<+|->H[H][:M[M][:S[S]]]"
          # for example: "+9", "-05", "+03:30", "-01:23:45", etc.
          # timezone = "local";

          # enable or disable automatic sync
          # auto_sync = true;

          # enable or disable automatic update checks
          update_check = false;

          # address of the sync server
          # sync_address = "https://api.atuin.sh";

          # how often to sync history. note that this is only triggered when a command
          # is ran, so sync intervals may well be longer
          # set it to 0 to sync after every command
          sync_frequency = "1h";

          # which search mode to use
          # possible values: prefix, fulltext, fuzzy, skim
          # search_mode = "fuzzy";

          # which filter mode to use
          # possible values: global, host, session, directory
          # filter_mode = "global";

          # With workspace filtering enabled, Atuin will filter for commands executed
          # in any directory within a git repository tree (default: false)
          workspaces = true;

          # which filter mode to use when atuin is invoked from a shell up-key binding
          # the accepted values are identical to those of "filter_mode"
          # leave unspecified to use same mode set in "filter_mode"
          filter_mode_shell_up_key_binding = "directory";

          # which search mode to use when atuin is invoked from a shell up-key binding
          # the accepted values are identical to those of "search_mode"
          # leave unspecified to use same mode set in "search_mode"
          # search_mode_shell_up_key_binding = "fuzzy";

          # which style to use
          # possible values: auto, full, compact
          # style = "auto";

          # the maximum number of lines the interface should take up
          # set it to 0 to always go full screen
          # inline_height = 0;

          # Invert the UI - put the search bar at the top , Default to `false`
          # invert = false;

          # enable or disable showing a preview of the selected command
          # useful when the command is longer than the terminal width and is cut off
          # show_preview = true;

          # what to do when the escape key is pressed when searching
          # possible values: return-original, return-query
          # exit_mode = "return-original";

          # possible values: emacs, subl
          # word_jump_mode = "emacs";

          # characters that count as a part of a word
          # word_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

          # number of context lines to show when scrolling by pages
          # scroll_context_lines = 1;

          # use ctrl instead of alt as the shortcut modifier key for numerical UI shortcuts
          # alt-0 .. alt-9
          # ctrl_n_shortcuts = false;

          # default history list format - can also be specified with the --format arg
          # history_format = "{time}\t{command}\t{duration}";

          # prevent commands matching any of these regexes from being written to history.
          # Note that these regular expressions are unanchored, i.e. if they don't start
          # with ^ or end with $, they'll match anywhere in the command.
          # For details on the supported regular expression syntax, see
          # https://docs.rs/regex/latest/regex/#syntax
          history_filter = [
            "^z(i)? .*"
            "^cd .*"
            # "^secret-cmd"
            # "^innocuous-cmd .*--secret=.+"
          ];

          # prevent commands run with cwd matching any of these regexes from being written
          # to history. Note that these regular expressions are unanchored, i.e. if they don't
          # start with ^ or end with $, they'll match anywhere in CWD.
          # For details on the supported regular expression syntax, see
          # https://docs.rs/regex/latest/regex/#syntax
          # cwd_filter = [
          #   "^/very/secret/area"
          # ];

          # Configure the maximum height of the preview to show.
          # Useful when you have long scripts in your history that you want to distinguish
          # by more than the first few lines.
          # max_preview_height = 4;

          # Configure whether or not to show the help row, which includes the current Atuin
          # version (and whether an update is available), a keymap hint, and the total
          # amount of commands in your history.
          # show_help = true;

          # Configure whether or not to show tabs for search and inspect
          # show_tabs = true;

          # Defaults to true. This matches history against a set of default regex, and will not save it if we get a match. Defaults include
          # 1. AWS key id
          # 2. Github pat (old and new)
          # 3. Slack oauth tokens (bot, user)
          # 4. Slack webhooks
          # 5. Stripe live/test keys
          # secrets_filter = true;

          # Defaults to true. If enabled, upon hitting enter Atuin will immediately execute the command. Press tab to return to the shell and edit.
          # This applies for new installs. Old installs will keep the old behaviour unless configured otherwise.
          enter_accept = true;

          # Defaults to false. If enabled, when triggered after && or ||, Atuin will complete commands to chain rather than replace the current line.
          command_chaining = true;

          # Defaults to "emacs".  This specifies the keymap on the startup of `atuin
          # search`.  If this is set to "auto", the startup keymap mode in the Atuin
          # search is automatically selected based on the shell's keymap where the
          # keybinding is defined.  If this is set to "emacs", "vim-insert", or
          # "vim-normal", the startup keymap mode in the Atuin search is forced to be
          # the specified one.
          keymap_mode = "vim-insert";

          # Cursor style in each keymap mode.  If specified, the cursor style is changed
          # in entering the cursor shape.  Available values are "default" and
          # "{blink,steady}-{block,underline,bar}".
          keymap_cursor = {
            emacs = "steady-block";
            vim_insert = "steady-bar";
            vim_normal = "steady-block";
          };

          network_connect_timeout = 60;
          network_timeout = 60;

          # Timeout (in seconds) for acquiring a local database connection (sqlite)
          # local_timeout = 5;

          # Set this to true and Atuin will minimize motion in the UI - timers will not update live, etc.
          # Alternatively, set env NO_MOTION=true
          # prefers_reduced_motion = false;

          stats = {
            # Set commands where we should consider the subcommand for statistics. Eg, kubectl get vs just kubectl
            common_subcommands = [
              "apt"
              "cargo"
              "composer"
              "dnf"
              "docker"
              "git"
              "go"
              "ip"
              "just"
              "kubectl"
              "make"
              "nix"
              "nmcli"
              "npm"
              "pecl"
              "pnpm"
              "podman"
              "port"
              "systemctl"
              "tmux"
              "yarn"
              ","
              "nh"
            ];

            # Set commands that should be totally stripped and ignored from stats
            common_prefix = [
              "sudo"
            ];

            # Set commands that will be completely ignored from stats
            # ignored_commands = [
            #   "cd"
            #   "ls"
            #   "vi"
            # ];
          };

          keys = {
            # Defaults to true. If disabled, using the up/down key won't exit the TUI when scrolled past the first/last entry.
            # scroll_exits = true;
          };

          dotfiles = {
            enabled = false;
          };

          sync = {
            # Enable sync v2 by default
            # This ensures that sync v2 is enabled for new installs only
            # In a later release it will become the default across the board
            records = true;
          };

          preview = {
            # which preview strategy to use to calculate the preview height (respects max_preview_height).
            # possible values: auto, static
            # auto: length of the selected command.
            # static: length of the longest command stored in the history.
            strategy = "static";
          };

          daemon = {
            # Enables using the daemon to sync. Requires the daemon to be running in the background. Start it with `atuin daemon`
            enabled = true;

            # How often the daemon should sync in seconds
            sync_frequency = 3600;

            # The path to the unix socket used by the daemon (on unix systems)
            # linux/mac: ~/.local/share/atuin/atuin.sock
            # windows: Not Supported
            # socket_path = "~/.local/share/atuin/atuin.sock";
            # socket_path = "/run/user/1000/atuin.sock";

            autostart = true;

            # Use systemd socket activation rather than opening the given path (the path must still be correct for the client)
            # linux: false
            # mac/windows: Not Supported
            systemd_socket = true;

            # The port that should be used for TCP on non unix systems
            # tcp_port = 8889;
          };
        };
      };
    };
}
