# nushell: nushell config
{ ren, inputs, ... }:
let
  addax = ren.helpers;
in
{
  # flake-file.inputs.nuenv = {
  #   url = "github:xav-ie/nuenv";
  #   inputs = {
  #     nixpkgs.follows = "nixpkgs";
  #     systems.follows = "systems";
  #   };
  # };

  ren.aspects.shells-nushell.os.nixpkgs.overlays = [
    # inputs.nuenv.overlays.default
  ];

  # perSystem =
  #   { pkgs, ... }:
  #   {
  #     selfPackages.test-hello = pkgs.writers.writeNuBin "run-me" /* nu */ ''
  #       def blue [msg: string] { $"(ansi blue)($msg)(ansi reset)" }
  #       blue "Hello world"
  #     '';
  #   };

  ren.aspects.shells-nushell.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe;
    in
    {
      programs.nushell = {
        enable = true;
        environmentVariables = {
          NU_EXPERIMENTAL_OPTIONS = "cell-path-types";
          SHELL = "${config.home.profileDirectory}/bin/nu"; # Stable path: long-lived parents (zellij) outlive store-path upgrades.
        };
        plugins = with pkgs.nushellPlugins; [
          # hcl
          # net
          # dbus
          # skim
          # gstat
          query
          # units
          polars
          # semver
          formats
          # highlight
          # desktop_notifications
        ];
        settings = {
          history = {
            file_format = "sqlite";
          };
          show_banner = false;
          edit_mode = "helix"; # "vi".

          rm = {
            always_trash = true;
          };
          cursor_shape = {
            vi_insert = "line";
            vi_normal = "block";
            helix_insert = "line";
            helix_normal = "block";
            emacs = "line";
          };
          completions = {
            algorithm = "fuzzy"; # prefix, substring, or fuzzy
            sort = "smart";
            external = {
              enable = true;
              max_results = 1000;
            };
            persistent_menus = true;
            # nushell 0.116 closes a sourced menu whose first answer is empty, and the partial-completion probe on
            #  menu open asks a `list` menu (fuzzy_completion_menu) before it has fetched anything, so it closes
            #  instantly. Without partial completions that probe is skipped.
            partial = false;
          };
          footer_mode = "auto";
          table = {
            padding = {
              left = 0;
              right = 0;
            };
            trim = {
              methodology = "wrapping";
              wrapping_try_keep_words = true;
              # or:
              # methodology = "truncating";
              # truncating_suffix = "...";
            };
            header_on_separator = true;
          };
          datetime_format.normal = "%d.%m.%y %I:%M:%S%p";

          highlight_resolved_externals = true;
          color_config = {
            shape_external = "light_red";
            shape_external_resolved = "light_green_bold";
            shape_internalcall = "light_green_bold";
            shape_garbage = "light_red_bold";
          };

          # Before each prompt is displayed
          # hooks.pre_prompt = /* nu */ ''
          # $env.config.hooks.pre_prompt? | default [] | append {||
          #   seq 1 (tput cols | into int) | shuffle | to text | ${getExe pkgs.python3Packages.sparklines} | ${getExe pkgs.lolcat}
          # '';
          # # After <enter> is pressed; before the commandline is executed
          # $env.config.hooks.pre_execution = []
          # # When a specified environment variable changes
          # hooks.env_change.<ENV>

          # Run if the PWD environment is different since the last REPL input.
          hooks.env_change.PWD = [
            /* nu */ ''
                {|before, after| print $"Changing directory: ($before) -> (ansi green_bold)($after)(ansi reset)" }

              # $env.config.hooks.env_change | get --optional PWD | default [] | append { ||
              #   ${getExe config.programs.envoluntary.package} shell export nushell | from json --objects | default {} | reduce --fold {} {|row, acc| $acc | merge $row} | load-env
              # }
            ''
          ];

          # Before Nushell output is displayed in the terminal.
          hooks.display_output = /* nu */ ''
            (if (term size).columns >= 100 {
              table --icons --expand
            } else {
              table --icons
            })
          '';

          # # When a command is not found
          # hooks.command_not_found = /* nu */ ''
          #   { |command_name| print (command-not-found $command_name | str trim) }
          # '';

          # # The env_change hook accepts a record with environment variable names as keys, and a list
          # # of hooks to run when that variable changes
          # $env.config.hooks.env_change = {}
        };
        # The config.nu can be anywhere you want if you like to edit your Nushell with Nu
        # configFile.source = ./.../config.nu;
        # for editing directly to config.nu
        extraConfig = addax.mkMergeShellCodeSep [
          /* nu */ ''
            # Import modules.

            use std/dirs
            use std/dirs shells-aliases *
            use std/clip
            use std/assert
            use std/bench
            use std/config
            use std/dt *
            use std/formats *
            use std/input
            use std/iter *
            use std/log
            use std/math
            # use std/null-device
            # use std/path
            use std/random
            # use std/repeat
            use std/xml

            use ${inputs.nu_scripts}/modules/jc
            use ${inputs.nu_scripts}/modules/filesystem/expand.nu
            module psub {
              ${builtins.readFile ./psub.nu}
            }
            use psub
          ''

          /* nu */ ''
            $env.config.max_last_result_size = 10mb
          ''

          /* nu */ ''
            # Set prompt indicators for vi mode.
            $env.PROMPT_INDICATOR_VI_NORMAL = ": ";
            $env.PROMPT_INDICATOR_VI_INSERT = "> ";
            $env.PROMPT_INDICATOR_HELIX_NORMAL = ": ";
            $env.PROMPT_INDICATOR_HELIX_INSERT = "> ";
          ''

          /* nu */ ''
            $env.ENV_CONVERSIONS = $env.ENV_CONVERSIONS | merge {
                "XDG_DATA_DIRS": {
                    from_string: {|s| $s | split row (char esep) | path expand --no-symlink }
                    to_string: {|v| $v | path expand --no-symlink | str join (char esep) }
                }
            }
          ''

          /* nu */ ''
            $env.config.keybindings ++= [
              {
                name: fuzzy_completion_menu
                modifier: none
                keycode: tab
                mode: [emacs, vi_normal, vi_insert, helix_normal, helix_insert]
                event: [
                  { send: ClearScreen }
                  { send: Repaint }
                  { send: menu name: fuzzy_completion_menu }
                ]
              }
              {
                name: fuzzy_completion_menu_open_or_accept_and_continue
                modifier: control
                keycode: char_j
                mode: [emacs, vi_normal, vi_insert, helix_normal, helix_insert]
                event: [
                  {
                    until: [
                      { send: menu name: fuzzy_completion_menu }
                      { send: Enter }
                    ]
                  }
                  { send: menu name: fuzzy_completion_menu }
                ]
              }
            ]

            def token-focus-at-cursor [line: string, cursor: int] {
              mut tokens = []
              mut i = 0
              let n = ($line | str length)
              mut in_squote = false
              mut in_dquote = false
              mut tok_start = -1
              while $i < $n {
                let ch = ($line | str substring $i..<($i + 1))
                if $in_squote {
                  if $ch == "'" { $in_squote = false }
                } else if $in_dquote {
                  if $ch == '"' { $in_dquote = false }
                } else if $ch == "'" {
                  $in_squote = true
                  if $tok_start == -1 { $tok_start = $i }
                } else if $ch == '"' {
                  $in_dquote = true
                  if $tok_start == -1 { $tok_start = $i }
                } else if $ch == ' ' {
                  if $tok_start != -1 {
                    $tokens = ($tokens | append {start: $tok_start, end: $i})
                    $tok_start = -1
                  }
                } else {
                  if $tok_start == -1 { $tok_start = $i }
                }
                $i = $i + 1
              }
              if $tok_start != -1 {
                $tokens = ($tokens | append {start: $tok_start, end: $n})
              }

              # cursor <= t.end (inclusive) so sitting right after the last char of a token --
              # still typing it, no trailing space yet -- keeps focusing that same token.
              mut focus = {start: -1, end: -1}
              for t in $tokens {
                if $cursor >= $t.start and $cursor <= $t.end {
                  $focus = $t
                  break
                }
                if $cursor < $t.start {
                  # Cursor sits before this token with a gap (whitespace) in between -- a fresh
                  # empty token belongs right at the cursor, not the token ahead of it.
                  $focus = {start: $cursor, end: $cursor}
                  break
                }
              }
              if $focus.start == -1 {
                # Cursor is beyond every token (end of line, or line is empty/all whitespace).
                $focus = {start: $cursor, end: $cursor}
              }

              {
                start: $focus.start
                end: $focus.end
                prefix: ($line | str substring 0..<$focus.start)
                token: ($line | str substring $focus.start..<$focus.end)
                suffix: ($line | str substring $focus.end..)
              }
            }

            # `get-candidates` fetches merged carapace+fish completions for an external
            # command's arguments, or nu's own structural/builtin completions otherwise --
            # used by fuzzy_completion_menu's source closure below. See fuzzy-get-candidates.nu.
            module fuzzy_candidates {
              ${builtins.readFile ./fuzzy-get-candidates.nu}
            }
            use fuzzy_candidates *

            def fuzzy-score [candidate: string, query: string] {
              let c = ($candidate | str lowercase)
              let q = ($query | str lowercase)
              if ($q | is-empty) { return 100 }
              if ($c == $q) { return 100 }
              if ($c | str starts-with $q) { return 90 }
              if ($c | str contains $q) { return 70 }
              let qchars = ($q | split chars)
              let qlen = ($qchars | length)
              mut qi = 0
              for ch in ($c | split chars) {
                if $qi < $qlen and $ch == ($qchars | get $qi) {
                  $qi = $qi + 1
                }
              }
              if $qi == $qlen { return 40 }
              -1
            }

            def fuzzy-filter [rows: list<string>, query: string] {
              $rows
              | each {|row|
                  let value = ($row | split row (char tab) | first)
                  # neg_len (not len): a single --reverse below then gives score descending
                  # *and* length ascending at once -- on a tied score, the shorter/tighter
                  # match (e.g. "checkout" over "check-attr" for query "chec") ranks first.
                  { row: $row, score: (fuzzy-score $value $query), neg_len: (0 - ($value | str length)) }
                }
              | where score > -1
              | sort-by score neg_len --reverse
              | get row
            }

            $env.config.menus ++= [{
              name: fuzzy_completion_menu
              only_buffer_difference: false
              marker: "> "
              type: {
                layout: list
                page_size: 15
                description_position: after
              }
              style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
              }
              source: {|buffer: string, place: record|
                let focus = (token-focus-at-cursor $buffer $place.cursor)
                let rows = if ($env._fuzzy_cache_prefix? == $focus.prefix) {
                  $env._fuzzy_cache_rows
                } else {
                  let candidates = (get-candidates ($focus.prefix + $focus.token))
                  if ($candidates | is-empty) {
                    $env._fuzzy_cache_prefix = $focus.prefix
                    $env._fuzzy_cache_rows = []
                    []
                  } else {
                    # uniq: carapace and fish can both return the exact same row for a given
                    # command (e.g. plain filename completion), now that both are always
                    # merged together in get-candidates.
                    let fresh = ($candidates | each {|c| $"($c.value)(char tab)($c.description)" } | uniq)
                    $env._fuzzy_cache_prefix = $focus.prefix
                    $env._fuzzy_cache_rows = $fresh
                    $fresh
                  }
                }
                if ($rows | is-empty) {
                  return []
                }
                let filtered = if ($focus.token | is-empty) {
                  $rows
                } else {
                  (fuzzy-filter $rows $focus.token)
                }
                $filtered | each {|row|
                  let parts = ($row | split row (char tab))
                  {
                    value: (($parts | first) + " ")
                    description: ($parts | get 1? | default "")
                    span: { start: $focus.start, end: $focus.end }
                  }
                }
              }
            }]

            $env.config.hooks.pre_prompt = (
              $env.config.hooks.pre_prompt? | default [] | append {||
                let safe_page_size = ([((term size).rows - 8), 1] | math max)
                $env.config.menus = ($env.config.menus | each {|menu|
                  if $menu.name == "fuzzy_completion_menu" {
                    $menu | update type.page_size $safe_page_size
                  } else {
                    $menu
                  }
                })
              }
            )
          ''

          /* nu */ ''
            # # Common ls aliases and sort them by type and then name
            # # Inspired by https://github.com/nushell/nushell/issues/7190
            # def lla [...args] { ls -la ...(if $args == [] {["."]} else {$args}) | sort-by type name -i }
            # def la  [...args] { ls -a  ...(if $args == [] {["."]} else {$args}) | sort-by type name -i }
            # def ll  [...args] { ls -l  ...(if $args == [] {["."]} else {$args}) | sort-by type name -i }
            # def l   [...args] { ls     ...(if $args == [] {["."]} else {$args}) | sort-by type name -i }
            def l [...args] {
              ls --all ...(if $args == [] {["."]} else {$args})
              | sort-by { $in.name | path expand | path type }
            }
          ''

          /* nu */ ''
            # Completions

            # $env.config.hooks.pre_prompt = ($env.config.hooks.pre_prompt? | default [] | append {||
            #   ...
            # })
            # FIXME: Does not get created.
            mkdir ($nu.cache-dir)
            touch ($nu.cache-dir | path join "carapace.nu")



            $env.config.menus ++= [{
              name: completion_menu
              only_buffer_difference: false # Search is done on the text written after activating the menu
              marker: "| "                  # Indicator that appears with the menu is active
              type: {
               layout: columnar          # Type of menu: columnar | ide
                columns: 1                # Number of columns where the options are displayed
                # col_width: 20             # Optional value. If missing all the screen width is used to calculate column width
                col_padding: 2            # Padding between columns
                    # If true, the cursor pos will be corrected, so the suggestions match up with the typed text:
                    # C:\> str
                    #      str join
                    #      str trim
                    #      str split
                correct_cursor_pos: false
              }
              style: {
                text: green                   # Text style
                selected_text: green_reverse  # Text style for selected option
                description_text: yellow      # Text style for description
              }
            }]

            # Completions
            # mainly pieced together from https://www.nushell.sh/cookbook/external_completers.html

            # carapace completions https://www.nushell.sh/cookbook/external_completers.html#carapace-completer
            # + fix https://www.nushell.sh/cookbook/external_completers.html#err-unknown-shorthand-flag-using-carapace
            # enable the package and integration bellow
            let carapace_completer = {|spans: list<string>|
              carapace $spans.0 nushell ...$spans
              | from json
              | if ($in | default [] | where value == $"($spans | last)ERR" | is-empty) { $in } else { null }
            }

            # fish completions https://www.nushell.sh/cookbook/external_completers.html#fish-completer
            let fish_completer = {|spans|
              # ${getExe pkgs.fish} --command $'complete "--do-complete=($spans | str join " ")"'
              # | $"value(char tab)description(char newline)" + $in
              # | from tsv --flexible --no-infer
              fish --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
              | from tsv --flexible --noheaders --no-infer
              | rename value description
              | update value {|row|
                let value = $row.value
                let need_quote = ['\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' "`"] | any {$in in $value}
                if ($need_quote and ($value | path exists)) {
                  let expanded_path = if ($value starts-with ~) {$value | path expand --no-symlink} else {$value}
                  $'"($expanded_path | str replace --all "\"" "\\\"")"'
                } else {$value}
              }
            }

            # zoxide completions https://www.nushell.sh/cookbook/external_completers.html#zoxide-completer
            let zoxide_completer = {|spans|
                $spans | skip 1 | zoxide query -l ...$in | lines | where {|x| $x != $env.PWD}
            }

            const NU_LIB_DIRS = $NU_LIB_DIRS ++ [($nu.default-config-dir | path join 'modules')]

            # some completions are only available through a bridge
            # eg. tailscale
            # https://carapace-sh.github.io/carapace-bin/setup.html#nushell
            carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
            source $"($nu.cache-dir)/carapace.nu"

            # multiple completions
            # the default will be carapace, but you can also switch to fish
            # https://www.nushell.sh/cookbook/external_completers.html#alias-completions
            let multiple_completers = {|spans|
              ## alias fixer start https://www.nushell.sh/cookbook/external_completers.html#alias-completions
              let expanded_alias = scope aliases
              | where name == $spans.0
              | get --optional 0.expansion

              let spans = if $expanded_alias != null {
                $spans
                | skip 1
                | prepend ($expanded_alias | split row ' ' | take 1)
              } else {
                $spans
              }
              ## alias fixer end

              match $spans.0 {
                __zoxide_z | __zoxide_zi | z | zi => $zoxide_completer
                nu => $fish_completer
                git => $fish_completer
                asdf => $fish_completer
                # nix => $fish_completer
                _ => $carapace_completer
                # _ => $fish_completer
              } | do $in $spans
            }
            $env.config.completions.external.completer = $multiple_completers;
          ''

          /* nu */ ''
            $env.PATH = ($env.PATH |
              split row (char esep) |
              # prepend /home/adda/.apps |
              append /usr/bin/env
            )
          ''
          /* nu */ ''
            # Envoluntary shell hook for nushell.

            # Output of: `envoluntary shell hook nushell`.
            $env.config.hooks.env_change.PWD = (
              $env.config.hooks.env_change | get --optional PWD | default [] | append { ||
                ${getExe config.programs.envoluntary.package} shell export nushell
                | from json --objects
                | default {}
                | reduce --fold {} {|row, acc| $acc | merge $row}
                | load-env
              }
            )
          ''

          /* nu */ ''
            # Sparklines on clear screen.

            $env.config.keybindings ++= [
              {
                name: clear_screen_with_sparklines
                modifier: control
                keycode: char_l
                mode: [emacs, vi_normal, vi_insert, helix_normal, helix_insert]
                event: [
                  { send: executehostcommand cmd: "clear --keep-scrollback; print-terminal-line-sparklines" }
                ]
              }
            ]

            def print-terminal-line-sparklines [] {
              seq 1 (tput cols | into int)
              | shuffle
              | to text
              | ${getExe pkgs.python3Packages.sparklines}
              | ${getExe pkgs.lolcat}
            }

            print-terminal-line-sparklines
          ''

        ];

        shellAliases = config.home.shellAliases // {
          ls = lib.mkForce "ls"; # Unset to use the nushell builtin.
          cp = lib.mkForce "cp"; # Unset to use the nushell builtin.
          mv = lib.mkForce "mv --interactive --progress"; # Unset to use the nushell builtin.
        };

        environmentVariables.config.abbreviations = with pkgs; {
          # FIXME: Does not run the alias mkdir --verbose...
          md = lib.mkForce "mkdir";
          fg = lib.mkForce "job unfreeze";
          "$?" = lib.mkForce "$env.LAST_EXIT_CODE";
          td = lib.mkForce "dirs add (mktemp --directory)";
          pd = lib.mkForce "dirs drop";
          gg = "goto";
        };
      };
    };

  ren.aspects.shells-nushell.abbreviations =
    { pkgs, ... }:
    let
      inherit (addax) getExeName;
    in
    with pkgs;
    {
      een = "exec ${getExeName nushell}";
    };
}
