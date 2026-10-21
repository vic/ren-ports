# fish: fish shell config
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.shells-fish.homeManager =
    {
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe;
      inherit (addax) getExeName getExeName';

      inherit (pkgs.python3Packages) sparklines;
    in
    {
      home.packages = with pkgs; [
        libnotify # notify-send for plugin 'done'.
      ];

      programs.fish = {
        enable = true;
        preferAbbrs = false;
        shellInit = lib.mkMerge [
          ''
            # Disable the fish greeting message.
            set -U fish_greeting

            # function fish_greeting
            #   fortune -a
            # end
          ''

          # ''
          #   if test ! -d ~/.config/fish/functions/fisher.fish
          #     curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
          #   end
          # ''
        ];
        interactiveShellInit = lib.mkMerge [
          ''
            # Set theme.
            fish_config theme choose fish_default_green
          ''

          # fish
          # ''
          #   # Configure fifc fzf completions.

          #   set -Ux fifc_editor $EDITOR

          #   ## Which keybindg to Bind the fifz fzf completions to.
          #   # set -U fifc_keybinding ctrl-x

          #   ## Bind keybindings for fzf in fifc to act like in fzf-tab.
          #   set FZF_DEFAULT_OPTS_FILE -Ux --bind=ctrl-i:down,btab:up,ctrl-space:toggle

          #   fifc \
          #     -r '.*\*{2}.*' \
          #     -s 'rg --hidden -l --no-messages (string match -r -g \'.*\*{2}(.*)\' "$fifc_commandline")' \
          #     -p 'batgrep --color --paging=never (string match -r -g \'.*\*{2}(.*)\' "$fifc_commandline") "$fifc_candidate"' \
          #     -f "--query \'\'" \
          #     -o 'batgrep --color (string match -r -g \'.*\*{2}(.*)\' "$fifc_commandline") "$fifc_candidate" | less -R' \
          #     -O 1
          # ''

          /* fish */ ''
            # Print expanded commands after each command invocation before the output.
            if status --is-interactive
              function preexec
                [ $1 != $2 ] && print -rP '%F{green}> $2%f'
              end
            end
          ''

          /* fish */ ''
            fish_vi_key_bindings
            set fish_cursor_default block
            set fish_cursor_insert line
            set fish_cursor_replace_one underscore
            set fish_cursor_visual block
            set fish_cursor_unknown block
            # bind --mode insert --sets-mode default jk repaint
          ''

          # fish
          ''
            # Printing colourful spark lines at the top of the terminal.
            print_terminal_line_sparklines
          ''
        ];
        shellInitLast = lib.mkMerge [
          # fzf-tab configuration.
          # (builtins.readFile ./fzf-tab-config.zsh)

          # fish
          ''
            function go-up-directories
              set --local path ""
              set --local limit $arvg[1]

              # Default to limit of 1.
              if test -z "$limit" || test "$limit" -le 0
                set --local limit 1
              end

              for i in (seq 1 $limit)
                set --local path = "../$path"
              end

              # Perform cd. Show error if cd fails.
              if test ! cd "$path"
                echo "Couldn't go up $limit dirs.";
              end
            end
          ''

          ''
            # TMPFIX: Until Zellij fixes completions generation and functions creation, a workaround is necessary.
            # Used workaround: https://github.com/zellij-org/zellij/issues/1933#issuecomment-2274464004.
            # autoload -U +X compinit && compinit
            # source <(${getExeName pkgs.zellij} setup --generate-completion fish \
              # | ${getExeName pkgs.gnused} -Ee 's/^(_(zellij) ).*/compdef \1\2/')
          ''

          ''
            # (builtins.readFile (
            #   builtins.fetchurl {
            #     url = "https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish";
            #     sha256 = "sha256:124nflgy5qpzah1ldz75wr39zdwzg65drsfz1ynz50m1pl3hsr2r";
            #   }
            # ))
            # fisher install jorgebucaran/fisher
          ''
        ];
        functions = {
          print_terminal_line_sparklines = {
            description = "Print colourful sparklines";
            body = "seq 1 $(tput cols) | sort -R | ${getExe sparklines} | ${getExe pkgs.lolcat}";
          };

          # Printing colourful spark lines at the top of the terminal before the prompt.
          clear_screen = {
            description = "Custom clear screen";
            body = ''
              command clear -x
              print_terminal_line_sparklines
              # echo
              # echo
              commandline --function repaint
            '';
          };
          clear_screen_newlines = {
            description = "Custom clear screen with inserted newlines";
            body = ''
              command clear -x
              print_terminal_line_sparklines
              echo
              echo
              commandline --function repaint
            '';
          };

          fish_user_key_bindings = {
            description = "Custom user key bindings";
            body = ''
              bind --user --mode insert ctrl-l clear_screen_newlines
              # FIXME: Seems to not work in the command mode for some reason.
              bind --user --mode command ctrl-l clear_screen_newlines

              bind --user --mode insert tab _fuzzy_tab_complete
              bind --user --mode default tab _fuzzy_tab_complete
            '';
          };

          home-manager-news = {
            description = "Get the home-manager news";
            body = ''
              ${getExeName pkgs.home-manager} news --flake .
            '';
          };

          list-desktop-files = {
            description = "Get list of desktop files";
            body = ''
              begin
                ls /run/current-system/sw/share/applications # For global packages.
                ls ~/.nix-profile/share/applications # For home-manager packages.
              end | sort
            '';
          };

          fzf-open-edit = {
            description = "Open file for editing using fzf";
            body = # fish
              ''
                set --local files (
                  ${getExeName' pkgs.fzf "fzf-tmux"} --query="$argv[1]" --multi --select-1 --exit-0 --preview "${getExeName pkgs.bat} --style=numbers --color=always --line-range :500 {}"
                )
                if test -n "$files"
                  $EDITOR $files
                end
              '';
          };

          _fuzzy_tab_complete = {
            description = "Fuzzy-pick completions for successive tokens via fzf/television, looping so accepting one immediately re-offers the next (mirrors nushell's live fuzzy_completion_menu -- fish has no equivalent in-place menu API, so this loops an interactive picker instead of staying open underneath the real command line); Escape keeps whatever was typed/edited and stops looping.";
            body = /* fish */ ''
              set --local first_iteration true

              while true
                # fish's own tokenizer (--current-token) is already cursor- and quote-aware,
                # unlike a naive space-split: it returns the *whole* token wherever the cursor
                # sits inside it (e.g. after moving there with the Left arrow), not just the
                # part left of the cursor. What it doesn't hand us directly is an exact prefix
                # (everything *before* that token): --current-process returns the whole buffer
                # regardless of cursor position (so subtracting $token's length from it, as
                # this used to do, only ever gave the right answer when the cursor was at the
                # very end of the line), and --cut-at-cursor --tokens-expanded (-cx) drops the
                # separating whitespace entirely. So the token's absolute start offset is
                # derived from --cursor (absolute position) minus --cursor --current-token
                # (position relative to the token itself), then sliced byte-exact out of the
                # raw buffer -- preserves the real separator, so concatenating prefix+query
                # later (in the reload below) needs no assumption about single-space
                # separators. Recomputed every loop iteration since the cursor moves each time
                # a candidate is accepted below.
                set --local token (commandline --current-token)
                set --local cursor_abs (commandline --cursor)
                set --local cursor_in_token (commandline --cursor --current-token)
                set --local token_start (math $cursor_abs - $cursor_in_token)
                set --local prefix (string sub -l $token_start -- (commandline))

                if not $first_iteration
                  # `commandline --function repaint` (below, after each accept) doesn't
                  # actually flush anything to the terminal until this whole bound function
                  # returns control to the reader -- confirmed live, even a half-second wait
                  # doesn't help. The very first fzf panel has the command line visible above
                  # it for free, drawn by the reader before this function was ever called;
                  # every panel after an in-loop accept needs it printed by hand instead, or
                  # it just shows a blank prompt line. \r ... \033[K (not a trailing \n):
                  # overwrites this same line in place on each iteration -- a plain \n here
                  # would print a new, permanent line into scrollback every single accept.
                  printf '\r%s\033[K' (commandline)
                end

                # Completion context should be prior completed tokens plus the token currently
                # under the cursor -- not the whole buffer (commandline --current-process),
                # which also includes anything typed *after* the cursor (e.g. if it was moved
                # left back into an earlier token) and would otherwise feed misleading context
                # to `complete --do-complete`.
                set --local before "$prefix$token"

                # `complete --do-complete` (fish's own resolution, including whatever carapace's
                # fish bridge already registered) badly under-delivers once the token is
                # non-empty: confirmed live, `git ` alone returns ~160 subcommands, but `git
                # chec` returns exactly one ("checkout"), silently dropping check-attr,
                # check-ignore, cherry-pick, etc. that a real prefix match should surface. So
                # for an external command's arguments, also call carapace directly -- its
                # `fish`-format output is already plain "value<TAB>description" (no JSON to
                # parse), and, like the nushell side of this, it returns the *full* candidate
                # set for the position regardless of what's typed so far, letting fzf's own
                # fuzzy filter (via --query below) do the actual narrowing.
                set --local spans (string split ' ' -- $before)
                set --local cmd0 $spans[1]
                set --local candidates (complete --do-complete -- $before)
                if test (count $spans) -gt 1
                  set --local carapace_result (carapace $cmd0 fish $spans 2>/dev/null)
                  set candidates $candidates $carapace_result
                end
                set candidates (printf '%s\n' $candidates | string collect | sort -u)

                if test -z "$candidates"
                  if test "$first_iteration" = true
                    # Nothing to fuzzy-complete at all (e.g. empty line) -- fall back to
                    # fish's own Tab, same as the very first version of this always did.
                    commandline --function complete
                  end
                  break
                end

                set --local cache_dir "$HOME/.cache/fuzzy-tab-complete"
                mkdir -p $cache_dir
                # Best-effort cleanup of the mktemp files below happens at the end of each
                # branch, but a Ctrl-C delivered straight to the fzf/tv process tree can abort
                # this whole function before that ever runs. Sweep anything orphaned by a
                # *previous* interrupted run here instead, bounded by age (1hr, generous since
                # a real pick finishes in seconds) so it never touches a file a concurrently
                # running invocation (e.g. another pane) still owns.
                find $cache_dir -type f -mmin +60 -delete 2>/dev/null

                set --local engine fzf
                set --query fuzzy_complete_engine
                and set engine $fuzzy_complete_engine

                set --local chosen

                switch $engine
                  case tv
                    # NOTE: television has no equivalent of fzf's `print-query` action, so
                    #  aborting (esc) here just leaves the original token untouched, unlike the
                    #  fzf branch below -- distinguishable from a real pick only by $chosen
                    #  being empty either way (no candidate value ever *is* the empty string).
                    # It also doesn't re-run `complete --do-complete` as the query is edited,
                    #  unlike fzf's `change:reload` below.
                    # --inline --height (not fullscreen): same reasoning as fzf's --height
                    #  below -- keeps the command line being built visible above the picker.
                    #  Television's --height wants a line count, not a percentage like fzf's.
                    # No --select-1 (dropped, was here before this looped): auto-accepting an
                    #  unambiguous single candidate was harmless for a one-shot pick, but in a
                    #  loop it can auto-accept *and* immediately reopen the next position for
                    #  a completely uninterrupted chain -- confirmed live, `cat` in a directory
                    #  with one file kept auto-accepting that same file forever, and since fzf
                    #  never actually exits, it keeps eating all input (which is exactly what
                    #  looked like broken Ctrl-J/Ctrl-R bindings): every accept needs an
                    #  explicit Enter now.
                    set --local tmp (mktemp --tmpdir=$cache_dir)
                    printf '%s\n' $candidates > $tmp
                    set chosen (${getExeName pkgs.television} --source-command "cat $tmp" --input "$token" --no-preview --inline --height (math (tput lines) x 4 / 5))
                    rm -f $tmp
                    if test -z "$chosen"
                      break
                    end
                  case '*'
                    # Re-run `complete -C` against the *edited* query on every keystroke, instead of just fuzzy-filtering
                    #  the initial candidate list: so e.g., deleting a character can surface completions that only
                    #  apply to the shorter prefix.
                    # $_fuzzy_prefix rides along as an env var (rather than being spliced into the command string) so it
                    #  never needs escaping.
                    # `complete -C` is prefix-based, so a reload that *replaced* the pool outright would break fuzzy
                    #  substring search: typing "ook" to find "book" would return nothing, since "ook" isn't a valid
                    #  prefix fish would ever complete.
                    # So union each reload with the original static list (passed via a temp file, same reasoning as the
                    #  env var above): fzf's own fuzzy filter still has the full original pool to search, on top of
                    #  whatever the reload freshly surfaces for the literal text.
                    set --local --export _fuzzy_prefix $prefix
                    set --local static_tmp (mktemp --tmpdir=$cache_dir)
                    printf '%s\n' $candidates > $static_tmp
                    set --local --export _fuzzy_static_file $static_tmp
                    set --local reload_bind (string join -- "" \
                      'change:reload:fish --command ' \
                      "'begin; cat \"\$_fuzzy_static_file\"; complete -C -- \"\$_fuzzy_prefix\$argv[1]\"; end | sort -u'" \
                      ' -- {q}' \
                    )
                    # --delimiter/--nth=1 below: score and match against the value field only
                    # -- without this, fzf fuzzy-matches the whole "value<TAB>description"
                    # row, so e.g. querying "chec" ranks git's `pr` (description "Checks out
                    # a pull request locally") above `checkout` itself -- confirmed live,
                    # same underlying bug as the one already fixed on the nushell side of
                    # this.
                    # --height (not fzf's default fullscreen/alternate-screen takeover):
                    # renders inline in the space below the cursor's current row instead, so
                    # the command line being built stays visible above it -- confirmed live,
                    # fullscreen mode was hiding it entirely.
                    # No --select-1: see the matching note on the tv branch above -- in a
                    # loop, auto-accepting an unambiguous single candidate can chain into an
                    # uninterrupted auto-accept-and-reopen sequence that never gives control
                    # back, which from the outside looks exactly like broken keybindings
                    # (fzf, still running, absorbs all input instead of the shell).
                    set chosen (
                      printf '%s\n' $candidates \
                      | ${getExeName pkgs.fzf} --height=80% --layout=reverse --border \
                          --delimiter=\t --nth=1 \
                          --query="$token" \
                          --bind='esc:print-query' \
                          --bind="$reload_bind"
                    )
                    rm --force $static_tmp

                    # A real accepted candidate row is always "value<TAB>description" (even
                    # with an empty description, the tab is still there); esc:print-query
                    # returns the bare edited text with no tab at all. That's the only
                    # reliable way to tell "picked something" apart from "gave up here" --
                    # fzf's exit status doesn't distinguish them, since print-query makes
                    # Escape "succeed" the same way accepting normally does.
                    if test (count (string split \t -- $chosen)) -le 1
                      if test -n "$chosen"
                        commandline --current-token -- (string escape -- $chosen)
                        commandline --function repaint
                      end
                      break
                    end
                end

                # Trailing space after the (separately escaped) value: finishes this
                # argument and lands the cursor ready to start the next one, so the *next*
                # loop iteration's token/prefix split correctly sees an empty token there,
                # instead of re-running this same completion against itself. Escaping "$value
                # " as one combined string (as this used to) quotes the space *inside* the
                # escaped result (e.g. 'pr ') instead of leaving it as a plain separator
                # *after* the token -- confirmed live -- since `string escape` has no way to
                # know the trailing space isn't meant to be part of the value.
                set --local value (string split -f1 -- \t $chosen)
                commandline --current-token -- (string escape -- $value)" "
                commandline --function repaint
                set first_iteration false
              end

              commandline --function repaint
            '';
          };

          # pushd_on_pwd_change = {
          #   description = "Push target to dirs stack on PWD change in interactive mode.";
          #   onVariable = "PWD";
          #   body = # fish
          #     ''
          #       if not status --is-interactive; or status --is-command-substitution
          #         return
          #       end

          #       # set --local MAX_DIR_HIST 25

          #       # Get the top entry of the stack (previous directory)
          #       set stack_top (dirs -n 1)

          #       # Only push if the previous stack entry is not the current directory and is not empty
          #       if test -n "$stack_top" -a "$stack_top" != "$PWD"
          #           pushd $stack_top > /dev/null
          #       end

          #       # FIZME: According to https://github.com/fish-shell/fish-shell/blob/master/share/functions/cd.fish.
          #       # if test "$PWD" != "$previous"
          #       #     set -q dirprev
          #       #     or set --local dirprev
          #       #     set -q dirprev[$MAX_DIR_HIST]
          #       #     and set -e dirprev[1]

          #       #     # If dirprev, dirnext, __fish_cd_direction
          #       #     # are set as universal variables, honor their scope.

          #       #     set -U -q dirprev
          #       #     and set -U -a dirprev $previous
          #       #     or set -g -a dirprev $previous

          #       #     set -U -q dirnext
          #       #     and set -U -e dirnext
          #       #     or set -e dirnext

          #       #     set -U -q __fish_cd_direction
          #       #     and set -U __fish_cd_direction prev
          #       #     or set -g __fish_cd_direction prev
          #       # end
          #     '';
          # };

        };
        plugins =
          let
            packagedPluginsFromList =
              plugins:
              map (plugin: {
                name = "${plugin}";
                inherit (pkgs.fishPlugins."${plugin}") src;
              }) plugins;
          in
          (packagedPluginsFromList [
            "autopair"
            "bang-bang"
            "bass"
            "colored-man-pages"
            "done"
            # "fifc"
            "fish-bd"
            "foreign-env"
            "forgit"
            "fzf-fish"
            # "grc"
            "humantime-fish"
            "plugin-git"
          ])
          ++ [
            # {
            #   name = "fzf-fish";
            #   src = pkgs.fishPlugins.fzf-fish.src;
            # }

            # Using this to get shell completion for programs added to the path through nix+direnv.
            # Issue to upstream into direnv: https://github.com/direnv/direnv/issues/443.
            {
              name = "completion-sync";
              src = pkgs.fetchFromGitHub {
                owner = "iynaix";
                repo = "fish-completion-sync";
                rev = "master";
                sha256 = "sha256-kHpdCQdYcpvi9EFM/uZXv93mZqlk1zCi2DRhWaDyK5g=";
              };
            }
          ];

        # shellAliases = { };
      };
      # xdg.configFile."fish/conf.d/script_loaded_before_every_shell.fish".text = ''
      # '';

      xdg.configFile."fish/themes/fish_default_green.theme".source = ./fish_default_green.theme;

      xdg.configFile."fish/completions/nix.fish".source =
        "${pkgs.nix}/share/fish/vendor_completions.d/nix.fish";
    };

  ren.aspects.shells-fish.abbreviations =
    { pkgs, ... }:
    let
      inherit (addax) getExeName;
    in
    with pkgs;
    {
      eef = "exec ${getExeName fish}";
    };
}
