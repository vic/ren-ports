# vcs: jujutsu + jjui config, jj wrappers, overlay, meld desktop tools
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.vcs.overlays = { ... }: final: prev: {
    jjui = (addax.omni prev).unified.jjui.packages.default;
  };

  ren.aspects.vcs.homeManager =
    {
      lib,
      pkgs,
      host,
      user,
      ...
    }:
    {
      home.packages = with pkgs; [
        lazyjj # Jujutsu TUI.
        # gg-jj # Jujutsu GUI.
        # jj-fzf # Jujutsu TUI.
      ];

      programs.mergiraf.enableJujutsuIntegration = true;

      # jj.
      programs.jujutsu = {
        enable = true;
        ediff = false;
        settings = {
          user = {
            name = user.vcs.authorName;
            email = user.vcs.email;
          };
          ui = {
            color = "auto"; # "always"
            #default-command = ["log", "--reversed"]
            # default-command = ["log"]

            # At this time, there is basically no reason to use the native backend. It is intented for eventual implementation of
            #  operations not possible in Git itself.
            #allow-init-native = true

            diff-formatter = [
              "difft"
              "--color=always"
              "$left"
              "$right"
            ];
            # diff-formatter = ["delta" "$left" "$right"];
            # diff-formatter = "delta";
            diff-editor = "oyui";
            diff-instructions = false;

            # merge-args = [
            #   "$left"
            #   "$right"
            # ];
            conflict-marker-style = "git";
          };

          merge-tools = {
            # merge-editor = "meld"; # Using mergiraf.
            oyui = {
              program = lib.getExe (addax.omni pkgs).unified.oyui.packages.oyui;
              edit-args = [
                "diff"
                "$left"
                "$right"
              ];
            };
          };
          signing = lib.optionalAttrs (host.signingKey != null) {
            behavior = "own";
            backend = "gpg";
            key = host.signingKey;
          };
          git = {
            auto-local-bookmark = false;
            # Prevent pushing work in progress or anything explicitly labeled "private".
            private-commits = ''
              description(glob:'wip:*') |
              description(glob:'[wW][iI][pP]') |
              description(glob:'private:*') |
              description(glob:'todo:*') |
              description(glob:'[tT][oO][dD][oO]')
            '';
          };
          revset-aliases = {
            # Github pages.
            # ghp = 'ancestors(bookmarks(gh-pages) | remote_bookmarks(gh-pages))'
            "wip" = "description(regex:\"^\\[(wip|WIP|todo|TODO)\\]|(wip|WIP|todo|TODO):?\")";

            # "immutable_heads()" = "builtin_immutable_heads() | ghp"

            # 'HEAD' = '@-'
            "user()" = "user(\"chocholaty.david@protonmail.com\")";
            "user(x)" = "author(x) | committer(x)";
          };
          template-aliases = {
            # "format_short_id(id)" = "id.shortest()";
            "format_short_id(id)" = "id.shortest().upper()";
            # "format_short_change_id(id)" = "format_short_id(id)"
          };
          aliases = {
            # Move all bookmarks from the ancestors of the current change to the parrent of the current change.
            tug = [
              "bookmark"
              "move"
              "--from"
              "heads(::@- & bookmarks())"
              "--to"
              "@-"
            ];
            n = [ "new" ];
            e = [ "edit" ];
            d = [ "describe" ];
            a = [ "abandon" ];
            fu = [
              "git"
              "fetch"
              "--remote"
              "upstream"
              "--branch"
              "master"
              "--branch"
              "main"
            ];
            # l = ["log"]
            # l = ["log", "-r", "@ | ancestors(immutable_heads().., 2) | trunk()"]
            # l = ["log", "-r", "@ | ancestors(immutable_heads().., 2) ~ ghp | trunk()"]
            # la = ["log", "-r", "..all() ~ ghp"]
          };
        };
      };

      # Jujutsu TUI.
      programs.jjui = {
        enable = true;
        settings = {
          preview = {
            show_at_start = true;
            extra_args = [
              "--config"
              "ui.diff.tool=['difft', '--color=always', '--width=150', '$left', '$right']"
            ];
          };
          ui = {
            auto_refresh_interval = 10; # In seconds.
            tracer.enabled = true;
          };
          suggest.exec.mode = "fuzzy";
          actions = [
            {
              name = "show-diff";
              lua = /* lua */ ''
                jj_diff("diff", "--revision", context.change_id(), "--color", "always")
                revisions.refresh()
              '';
            }
            {
              name = "show-oplog-diff";
              lua = /* lua */ ''
                jj_diff("op", "show", context.operation_id(), "--color", "always")
              '';
            }
            {
              name = "show-after-revisions";
              lua = /* lua */ ''
                revset.set("::" .. context.change_id())
              '';
            }
            {
              name = "resolve-with-oyui";
              lua = /* lua */ ''
                jj_interactive("resolve", "--tool", "oyui")
              '';
            }
            {
              name = "tug";
              lua = /* lua */ ''
                jj_async("bookmark", "move", "--from", closest_bookmark(context.change_id()), "--to", closest_pushable(context.change_id()))
              '';
            }
          ];
          bindings = [
            {
              action = "show-diff";
              key = "U";
              scope = "revisions";
              desc = "show diff";
            }
            {
              action = "show-after-revisions";
              key = "M";
              scope = "revisions";
              desc = "show after revisions";
            }
            {
              action = "show-oplog-diff";
              key = "ctrl+o";
              scope = "revisions";
              desc = "show oplog diff";
            }
            {
              action = "tug";
              key = "ctrl+t";
              scope = "revisions";
              desc = "tug the closest bookmarks to the closest pushable change";
            }
            # {
            #   action = "resolve-with-vscodium";
            #   key = "R";
            #   scope = "revisions";
            #   desc = "resolve with VSCodium";
            # }
          ];
          # custom_commands = {
          #   "new master" = {
          #     args = [
          #       "new"
          #       "master"
          #     ];
          #   };
          #};
        };
      };

      programs.television.channels.jj-log = {
        metadata = {
          name = "jj-log";
          description = "A channel to select a change from jj log entries";
          requirements = [ "jj" ];
        };
        source = {
          command = "${lib.getExe pkgs.jujutsu} log --template builtin_log_oneline --no-graph";
          output = "{split: :0}";
        };
        preview = {
          command = "${lib.getExe pkgs.jujutsu} show '{0}'";
        };
      };

      # Wrapper for jujutsu and jjui, providing the 'jj' command that calls 'jjui' when no arguments are given and
      #  jujutsu's 'jj' otherwise. This can't live in programs.nushell.extraConfig (i.e. config.nu): nushell
      #  unconditionally sources every installed package's share/nushell/vendor/autoload/*.nu script *after*
      #  config.nu finishes, no matter what config.nu contains, and jujutsu's own package ships exactly such a
      #  script declaring `export extern jj [...]` (for completions) -- which then silently shadows a same-named
      #  `def` from config.nu, since whichever declaration of a name loads last wins. Confirmed by reproducing it
      #  outside the real shell: sourcing config.nu then jujutsu's vendor jj.nu leaves `which jj` reporting type
      #  "external" pointing at that vendor script, and bare `jj` runs the real binary instead of jjui.
      #
      #  ~/.local/share/nushell/vendor/autoload is nushell's documented exception: it's the one vendor-autoload
      #  directory guaranteed to be sourced *last*, specifically so the user can override any package's vendor
      #  script -- confirmed empirically too: sourcing this same wrapper right after jujutsu's vendor jj.nu makes
      #  `which jj` (and calling it) correct again.
      xdg.dataFile."nushell/vendor/autoload/jj.nu".text = /* nu */ ''
        @complete external
        def --wrapped jj [...args] {
          if ($args | is-empty) {
            jjui
          } else {
            ^jj ...$args
          }
        }

        @complete external
        def --wrapped "jj bookmark track" [...args] {
          if ($args | is-empty) {
            ${lib.getExe pkgs.fish} --command "${lib.getExe pkgs.jujutsu} bookmark track --remote (${lib.getExe pkgs.television} git-remotes) (${lib.getExe pkgs.television} git-branch)"
          } else {
            ${lib.getExe pkgs.jujutsu} bookmark track ...$args
          }
        }
      '';

      # Wrapper for jujutsu and jjui, providing the 'jj' command that calls 'jjui' when no arguments are given and
      #  jujutsu's 'jj' otherwise, the same as for nushell above. 'wraps = "jj"' keeps the man-page-derived
      #  completions generated for the real 'jj' binary working for this wrapper function too.
      programs.fish.functions.jj = {
        description = "jj, or jjui with no arguments";
        wraps = "jj";
        body = # fish
          ''
            if test (count $argv) -eq 0
              jjui
            else if test "$argv[1]" = bookmark; and test "$argv[2]" = track; and test (count $argv) -eq 2
              command jj bookmark track --remote (${lib.getExe pkgs.television} git-remotes) (${lib.getExe pkgs.television} git-branch)
            else
              command jj $argv
            end
          '';
      };
    };

  ren.aspects.vcs-desktop.homeManager =
    { lib, pkgs, ... }:
    {
      programs.jujutsu.settings.merge-tools.meld = {
        program = lib.getExe pkgs.meld;
        merge-args = [
          "$left"
          "$base"
          "$right"
          "-o"
          "$output"
          "--auto-merge"
        ];
      };

      programs.jjui.settings = {
        actions = [
          {
            name = "resolve-with-meld";
            lua = /* lua */ ''
              jj_interactive("resolve", "--tool", "meld")
            '';
          }
          {
            name = "resolve-with-vscodium";
            lua = /* lua */ ''
              jj_interactive("resolve", "--tool", "vscodium")
            '';
          }
        ];
        bindings = [
          {
            action = "resolve-with-meld";
            key = "R";
            scope = "revisions";
            desc = "resolve with Meld";
          }
        ];
      };
    };

  ren.aspects.vcs.abbreviations =
    { pkgs, ... }:
    let
      inherit (addax) getExeName;
    in
    with pkgs;
    {
      jjbt = "${getExeName jujutsu} bookmark track";
      # j = "${getExeName jujutsu}";
    };
}
