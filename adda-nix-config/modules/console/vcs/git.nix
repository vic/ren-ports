# vcs: git config, signing, desktop client + abbreviation
{ ren, ... }:
let
  addax = ren.helpers;
in
{
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
        delta
        diff-so-fancy
        git-extras
        ec
      ];

      programs.mergiraf = {
        enable = true;
        enableGitIntegration = true;
      };

      programs.git = {
        enable = true;
        settings = {
          aliases = {
            a = "add";
            aa = "add --update";
            aaa = "add --all";
            ap = "add --patch";
            aar = "!git aa && git ar";
            aaar = "!git aaa && git ar";
            ar = "commit --amend --reset-author --verbose";
            ars = "commit --amend --reset-author --gpg-sign --verbose";
            arso = "commit --amend --reset-author --signoff --verbose";
            arss = "commit --amend --reset-author --gpg-sign --signoff --verbose";
            c = "commit --verbose";
            ca = "commit --all --verbose";
            cs = "commit --gpg-sign --verbose";
            csa = "commit --gpg-sign --all --verbose";
            cso = "commit --signoff --verbose";
            csoa = "commit --signoff --all --verbose";
            css = "commit --gpg-sign --signoff --verbose";
            cssa = "commit --gpg-sign --signoff --all --verbose";
            authors = "!git log --pretty=format:%aN | sort | uniq -c | sort -rn";
            bl = "blame";
            br = "branch --verbose";
            bra = "branch --all --verbose";
            brd = "branch -d --verbose";
            brdf = "branch -D --verbose";
            brm = "branch -m --verbose";
            cc = "rev-list --count";
            cca = "rev-list --all --count";
            clear = "reset --hard";
            cl = "clone";
            cl1 = "clone --depth=1";
            conflicts = "diff --name-only --diff-filter=U --relative";
            cm = "checkout master";
            co = "checkout";
            cob = "checkout -b";
            com = "checkout master";
            cop = "checkout -p";
            cp = "cherry-pick";
            d = "diff";
            da = "diff HEAD";
            dc = "checkout --";
            dca = "checkout -- :/";
            ds = "diff --staged";
            # https://github.com/s3rvac/git-edit-index
            ei = "edit-index";
            f = "fetch --all --prune";
            g = "grep";
            hist = "log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short";
            ignored = "ls-files --exclude-standard --ignored --others";
            i = "init";
            l = "!git --no-pager log -20 --pretty='format:%C(yellow)%h %C(green)%ai %C(bold blue)%an %C(red)%d%C(reset) %s'; echo";
            la = "!git config -l | grep alias | cut -c 7- | less";
            ll = "log --pretty='format:%C(yellow)%h %C(green)%ai %C(bold blue)%an %C(red)%d%C(reset) %s'";
            lf = "log --name-status --pretty='format:%C(yellow)%h %C(green)%ai %C(bold blue)%an %C(red)%d%C(reset) %s'";
            lfn = "!git ls-tree -r master --name-only";
            lfna = "! git log --pretty=format: --name-only --diff-filter=A | sort - | sed '/^$/d'";
            lp = "log --patch --format=fuller";
            lg = "log --graph --pretty='format:%C(yellow)%h %C(green)%ai %C(bold blue)%an %C(red)%d%C(reset) %s %Cgreen(%cr)'";
            lga = "log --all --graph --branches --remotes --tags --pretty='format:%C(yellow)%h %C(green)(%ad) %C(bold blue)%an %C(red)%d%C(reset) %s %Cgreen(%cr)'";
            m = "merge --no-ff";
            ma = "merge --abort";
            p = "push";
            pa = "push all";
            pf = "push --force-with-lease";
            pfa = "push --force-with-lease all";
            pff = "push --force";
            pffa = "push --force all";
            pb = "!git push --set-upstream origin `git rev-parse --abbrev-ref HEAD`";
            db = "!git branch --delete \"$1\" && git push origin --delete \"$1\" #";
            pl = "pull --rebase=merges --autostash --stat --prune";
            r = "reset";
            rh = "reset HEAD~";
            rb = "rebase --rebase-merges";
            rba = "rebase --abort";
            rbc = "rebase --continue";
            rbi = "rebase --interactive";
            rbis = "rebase --interactive --gpg-sign";
            rbim = "rebase --interactive master";
            rf = "reflog";
            rv = "remote --verbose";
            s = "status --short --branch";
            sm = "submodule";
            sma = "submodule add";
            smf = "submodule foreach";
            sms = "submodule status --recursive";
            smu = "submodule update --init --recursive";
            sh = "stash";
            sha = "stash apply";
            shd = "stash drop";
            shl = "stash list";
            shp = "stash pop";
            shs = "stash show -p";
            sw = "show --format=fuller --show-signature";
            sf = "show --pretty=\"format:\" --name-status";
            sync-fork = "!git fetch upstream && git rebase upstream/`git rev-parse --abbrev-ref HEAD` && git push";
            tags = "tag --list -n1";
            showtag = "show --quiet";
            today = "!git ll --since=midnight";
            undo = "!git reset --soft HEAD^ && git reset";

            # https://github.com/aanand/git-up
            u = "!git reset --soft HEAD^ && git reset";
            wip = "!git add --all && git commit -m 'WIP'";
          };
          user = {
            name = user.vcs.authorName;
            email = user.vcs.email;
          };

          pull.rebase = true;
          core = {
            whitespace = "trailing-space,space-before-tab";
            pager = lib.getExe pkgs.delta;
            # pager = difft;
            editor = "hx";
          };
          init = {
            defaultBranch = "master";
          };
          color = {
            ui = true;
            branch = "auto";
            interactive = "auto";
            pager = true;
          };
          # color.branch = {
          #   current = "green";
          #   local = "normal";
          #   remote = "red";
          #   plain = "normal";
          # };
          # "color status" = {
          #   header = "normal";
          #   added = "red";
          #   updated = "green";
          #   changed = "red";
          #   untracked = "red";
          #   nobranch = "red";
          # };
          # "color diff" = {
          #   plain = "normal";
          #   meta = "bold";
          #   frag = "cyan";
          #   old = "red";
          #   new = "green";
          #   commit = "yellow";
          #   whitespace = "normal red";
          # };
          # "color grep" = {
          #   match = "normal";
          # };
          # "color interactive" = {
          #   prompt = "normal";
          #   header = "normal";
          #   help = "normal";
          #   error = "normal";
          # };
          interactive.diffFilter = "${lib.getExe pkgs.delta} --color-only";
          # interactive.diffFilter = "${difft}";
          pager = {
            # show = "${difft}";
            # diff = "${difft}";
            show = "diff-so-fancy | less --tabs=1,5 -RFX";
            diff = "diff-so-fancy | less --tabs=4 -RFXS --pattern '^(Date|added|deleted|modified): '";
          };
          delta = {
            line-numbers = true;
            plus-color = "#012800";
            minus-color = "#340001";
            syntax-theme = "Monokai Extended";
          };
          commit.gpgsign = host.signingKey != null;
          diff = {
            # Allow `git diff` to do basic rename and copy detection.
            renames = "copies";
            renameLimit = 10000;
          };
          # Automatically prune (remove local branches that were removed from remote) during `git fetch`.
          fetch.prune = true;
          gc.autoDetach = false;
          # Use a submodule-aware status.
          status.submoduleSummary = true;
          push = {
            # `git push` without any refspec will push the current branch out to the               same name at the
            #  remote repository only when it is set to track the branch with the same name over there.
            default = "current";
            # Check that all submodules have been properly pushed before pushing the main project.
            recurseSubmodules = "check";
          };
          # Automatically stash before a rebase and unstash afterwards.
          rebase.autoStash = true;
          # The used merge tool.
          # merge.tool = "meld";
          merge-tools.meld.merge-args = [
            "$left"
            "$base"
            "$right"
            "-o"
            "$output"
            "--auto-merge"
          ];
          include.path = ".gitconfig.local";

          # Settings for the `git-edit-index` script.
          # https://github.com/s3rvac/git-edit-index
          credential.helper = "cache --timeout=0";

          # Settings for the `git-edit-index` script.
          # https://github.com/s3rvac/git-edit-index
          git-edit-index.onEmptyBuffer = "act";
          # "git-up rebase" = {
          # Settings for the `git-up` script.
          # https://github.com/aanand/git-up

          #	arguments = --preserve-merges
          #	log-hook = "echo \"* changes on $1:\"; git log --pretty='format:%C(yellow)%h %C(green)%ai %C(bold blue)%an %C(red)%d%C(reset) %s' $1..$2"
          # };
          # Using PyGitUp: https://github.com/msiemens/PyGitUp
          PyGitUp = { };

          advie = {
            # Make git a little less verbose.
            # pushNonFastForward = false
            # statusHints = false
            # commitBeforeMerge = false
            # resolveConflict = false
            # implicitIdentity   = false
            detachedHead = false;
          };

          sendemail = {
            # Review and edit each patch before sending.
            # annotate = true
            # ; Always confirm before sending.
            # confirm = always
            # ; Don't send every patch as a reply to the previous patch.
            # chainreplyto = false
          };
          cola = {
            startupmode = "list";
            spellcheck = false;
            statusshowtotals = true;
          };
        };
        signing = {
          key = host.signingKey;
          signByDefault = host.signingKey != null;
          format = "openpgp";
        };
        ignores = [
          "*~"
          "*.swp"
          ".jj/"
          # Agent workspaces (see the `workspaces` rule in modules/aspects/ai/rules.nix) live in
          #  `<repo root>/.workspaces/<topic>`. Unanchored on purpose: these land in
          #  ~/.config/git/ignore, git's default user-wide excludes file, so the directory is
          #  ignored at any depth -- nested repos, submodules and monorepo subprojects get the
          #  same treatment without another entry. jj reads the same file, verified for both.
          ".workspaces/"
        ];
      };

      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
          prompt = "enabled";
          aliases = {
            pc = "pr checkout";
            pv = "pr view";
          };
        };
      };

      programs.gh-dash = {
        enable = true;
        settings = {
          prSections = [
            {
              title = "My Pull Requests";
              filters = "is:open author:@me sort:updated-desc";
            }
          ];
        };
      };

      programs.difftastic = {
        enable = true;
        options = {
          # color = "always";
          sort-paths = true;
          tab-width = 4;
        };
        git = {
          enable = true;
          mode = "both";
        };
      };

      programs.lazyworktree = {
        enable = true;
        settings = {
          # auto_fetch_prs = false;

          # worktree_dir: ~/.local/share/worktrees
          # sort_mode: switched  # Options: "path", "active" (commit date), "switched" (last accessed)
          # auto_refresh: true
          # refresh_interval: 10  # Seconds
          # disable_pr: false     # Disable all PR/MR fetching and display (default: false)
          # icon_set: nerd-font-v3
          # search_auto_select: false
          # fuzzy_finder_input: false
          # palette_mru: true         # Enable MRU (Most Recently Used) sorting for command palette
          # palette_mru_limit: 5      # Number of recent commands to show (default: 5)
          # max_untracked_diffs: 10
          # max_diff_chars: 200000
          # max_name_length: 95       # Maximum length for worktree names in table display (0 disables truncation)
          # theme: ""       # Leave empty to auto-detect based on terminal background colour
          #                 # (defaults to "rose-pine" for dark, "dracula-light" for light).
          #                 # Options: see the Themes section below.
          # git_pager: delta
          # pager: "less --use-color --wordwrap -qcR -P 'Press q to exit..'"
          # editor: nvim
          # git_pager_args:
          #   - --syntax-theme
          #   - Dracula
          # trust_mode: "tofu" # Options: "tofu" (default), "never", "always"
          # merge_method: "rebase" # Options: "rebase" (default), "merge"
          # session_prefix: "wt-" # Prefix for tmux/zellij session names (default: "wt-")
          # # Branch name generation for issues and PRs
          # issue_branch_name_template: "issue-{number}-{title}" # Placeholders: {number}, {title}, {generated}
          # pr_branch_name_template: "pr-{number}-{title}" # Placeholders: {number}, {title}, {generated}
          # # Automatic branch name generation (see "Automatically Generated Branch Names")
          # branch_name_script: "" # Script to generate names from diff/issue/PR content
          # init_commands:
          #   - link_topsymlinks
          # terminate_commands:
          #   - echo "Cleaning up $WORKTREE_NAME"
          # custom_commands:
          #   t:
          #     command: make test
          #     description: Run tests
          #     show_help: true
          #     wait: true
          # # Custom worktree creation menu items
          # custom_create_menus:
          #   - label: "From JIRA ticket"
          #     description: "Create from JIRA issue"
          #     command: "jayrah browse 'SRVKP' --choose"
          #     interactive: true  # TUI-based commands need this to suspend lazyworktree
          #     post_command: "git commit --allow-empty -m 'Initial commit for ${WORKTREE_BRANCH}'"
          #     post_interactive: false  # Run post-command in background
          #   - label: "From clipboard"
          #     description: "Use clipboard as branch name"
          #     command: "pbpaste"
        };
      };
    };

  ren.aspects.vcs-desktop.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.github-desktop ];
    };

  ren.aspects.vcs.abbreviations =
    { pkgs, ... }:
    let
      inherit (addax) getExeName;
    in
    with pkgs;
    {
      g = "${getExeName git}";
    };
}
