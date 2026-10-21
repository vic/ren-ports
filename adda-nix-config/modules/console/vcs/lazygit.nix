# vcs: lazygit config + abbreviation
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.vcs.homeManager =
    { lib, pkgs, ... }:
    let
      inherit (lib) getExe;
    in
    {
      programs.lazygit = {
        enable = true;
        settings = {
          git = {
            diffRenderers = [
              {
                colorArg = "always";
                # command = "delta --dark --paging=never";
                command = "${getExe pkgs.difftastic}";
                # command = "diff-so-fancy";
                # useConfig = true; # Uncomment to respect existing git paging config
              }
              {
                colorArg = "always";
                command = "${getExe pkgs.delta} --dark --paging=never";
                # pager = "diff-so-fancy";
                # useConfig = true; # Uncomment to respect existing git paging config
              }
            ];
            # branchLogCmd = "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium --oneline {{branchName}} --";
            # branchLogCmd = "git log --all --graph --branches --remotes --tags --pretty='format:%C(yellow)%h %C(green)(%ad) %C(bold blue)%an %C(red)%d%C(reset) %s %Cgreen(%cr)'";
          };

          gui = {
            branchColors = {
              "docs" = "#11aaff";
            }; # use a light blue for branches beginning with 'docs/'
          };

          os = {
            open = "hx";
            editPreset = "hx"; # 'nvim'
          };

          keybinding = {
            commits = {
              renameCommit = "R";
              renameCommitWithEditor = "r";
            };
            files = {
              commitChanges = "C";
              commitChangesWithEditor = "c";
            };
          };

          # To skip without creating a new repo when launching not in a repository directory: 'skip', 'create', 'prompt'.
          notARepository = "skip";

          # customCommands converted from prior YAML examples follow
          # Converted customCommands from original commented YAML. NOTE: Some keys are duplicated in the original
          # (e.g. <ctrl+r>, v, G, b, t, <ctrl+c>, <ctrl+a>, <ctrl+e>) but appear in different contexts. Lazygit matches on context
          # so they can coexist; duplicates within the same context were kept only once.
          customCommands = [
            # Comparing a file in a previous revision with the working copy.
            {
              key = "f";
              command = "git difftool -y {{.SelectedLocalCommit.Sha}} -- {{.SelectedCommitFile.Name}}";
              context = "commitFiles";
              description = "Compare (difftool) with local copy";
            }
            # Create Gerrit review.
            {
              key = "<ctrl+e>";
              command = "git push origin HEAD:refs/for/{{.CheckedOutBranch.Name}}";
              context = "global";
              loadingText = "pushing";
            }
            # Push to a specific remote repository with a chosen strategy.
            {
              key = "<ctrl+shift+p>";
              description = "Push to a specific remote repository";
              context = "global";
              loadingText = "Pushing ...";
              prompts = [
                {
                  type = "menuFromCommand";
                  title = "Which remote repository to push to?";
                  command = "bash -c 'git remote --verbose | grep '/.* (push)'";
                  filter = "(?P<remote>.*)\\s+(?P<url>.*) (push)";
                  valueFormat = "{{ .remote }}";
                  labelFormat = "{{ .remote | bold | cyan }} {{ .url }}";
                }
                {
                  type = "menu";
                  title = "How to push?";
                  options = [
                    { value = "push"; }
                    { value = "push --force-with-lease"; }
                    { value = "push --force"; }
                  ];
                }
              ];
              command = "git {{index .PromptResponses 1}} {{index .PromptResponses 0}}";
            }
            # Push to a specific remote branch.
            {
              key = "<ctrl+g>";
              context = "global";
              loadingText = "Pushing...";
              prompts = [
                {
                  type = "input";
                  title = "Which branch to push?";
                }
              ];
              command = "git push origin {{index .PromptResponses 0}}";
            }
            # Pushing a specific (and all preceding) commit.
            {
              key = "<ctrl+shift+o>";
              command = "git push {{.SelectedRemote.Name}} {{.SelectedLocalCommit.Sha}}:{{.SelectedLocalBranch.RefName}}";
              context = "commits";
              loadingText = "Pushing...";
              description = "Push a specific (and all preceding) commits";
            }
            # Open existing GitHub PR in browser.
            {
              key = "G";
              command = "gh pr view -w {{.SelectedLocalBranch.Name}}";
              context = "localBranches";
              description = "Open GitHub PR in browser";
            }
            # Open existing GitLab MR in browser.
            {
              key = "G";
              command = "glab mr view -w {{.SelectedLocalBranch.UpstreamBranch}}";
              context = "localBranches";
              description = "Go to MR in GitLab";
              output = "log";
            }
            # Checkout branch via GitHub PR id.
            {
              key = "v";
              prompts = [
                {
                  type = "input";
                  title = "PR id:";
                }
              ];
              command = "hub pr checkout {{index .PromptResponses 0}}";
              context = "localBranches";
              loadingText = "Checking out PR";
            }
            # List and Select GitHub PR to checkout.
            {
              key = "V";
              context = "localBranches";
              loadingText = "Checking out GitHub Pull Request...";
              command = "gh pr checkout {{.Form.PullRequestNumber}}";
              prompts = [
                {
                  type = "menuFromCommand";
                  title = "Which PR to check out?";
                  key = "PullRequestNumber";
                  command = ''gh pr list --json number,title,headRefName,updatedAt --template '{{`{{range .}}{{printf "#%v: %s - %s (%s)" .number .title .headRefName (timeago .updatedAt)}}{{end}}`}}'';
                  filter = "#(?P<number>[0-9]+): (?P<title>.+) - (?P<ref_name>[^ ]+).*";
                  valueFormat = "{{.number}}";
                  labelFormat = ''{{"#" | black | bold}}{{.number | white | bold}} {{.title | yellow | bold}}{{" [" | black | bold}}{{.ref_name | green}}{{"]" | black | bold}}'';
                }
              ];
            }
            # Opening git mergetool for the selected file.
            {
              key = "M";
              command = "git mergetool {{ .SelectedFile.Name }}";
              context = "files";
              loadingText = "Opening git mergetool";
              output = "terminal";
            }
            # Pruning deleted remote branches.
            {
              key = "<ctrl+e>";
              command = "git remote prune {{.SelectedRemote.Name}}";
              context = "remotes";
              loadingText = "Pruning...";
              description = "prune deleted remote branches";
            }
            # Pruning merged local branches.
            {
              key = "b";
              command = "git branch --merged master | grep -v '^[ *]*master$' | xargs -r git branch -d";
              context = "localBranches";
              loadingText = "Pruning...";
              description = "Prune local branches that have been merged to master";
            }
            # Pruning branches no longer on the remote.
            {
              key = "G";
              command = ''git fetch -p && for branch in $(git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | awk '$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'); do git branch -D $branch; done'';
              context = "localBranches";
              loadingText = "Pruning...";
              description = "Prune local branches no longer on its remote; (G)one.";
            }

            # TODO: Process the rest and convert from the compendium of documented custom commands on the Lazygit repo wiki.
            #https://github.com/jesseduffield/lazygit/wiki/Custom-Commands-Compendium

            # Browse commit on GitHub using hub
            # {
            #   key = "<ctrl+r>";
            #   command = "hub browse -- \"commit/{{.SelectedLocalCommit.Sha}}\"";
            #   context = "commits";
            #   description = "Browse on GitHub";
            # }
            # Toggle file staged / unstaged
            {
              key = "a";
              command = "git {{if .SelectedFile.HasUnstagedChanges}} add {{else}} reset {{end}} {{.SelectedFile.Name}}";
              context = "files";
              description = "toggle file staged";
            }
            # Start git-flow branch
            {
              key = "n";
              context = "localBranches";
              loadingText = "creating branch";
              prompts = [
                {
                  type = "menu";
                  title = "What kind of branch is it?";
                  options = [
                    {
                      name = "feature";
                      description = "a feature branch";
                      value = "feature";
                    }
                    {
                      name = "hotfix";
                      description = "a hotfix branch";
                      value = "hotfix";
                    }
                    {
                      name = "release";
                      description = "a release branch";
                      value = "release";
                    }
                  ];
                }
                {
                  type = "input";
                  title = "What is the new branch name?";
                  initialValue = "";
                }
              ];
              command = "git flow {{index .PromptResponses 0}} start {{index .PromptResponses 1}}";
            }
            # Checkout remote branch as FETCH_HEAD then checkout
            {
              key = "r";
              description = "Checkout a remote branch as FETCH_HEAD";
              command = "git fetch {{index .PromptResponses 0}} {{index .PromptResponses 1}} && git checkout FETCH_HEAD";
              context = "remotes";
              prompts = [
                {
                  type = "input";
                  title = "Remote:";
                  initialValue = "{{index .SelectedRemote.Name }}";
                }
                {
                  type = "menuFromCommand";
                  title = "Remote branch:";
                  command = "git branch -r --list {{index .PromptResponses 0}}/*";
                  filter = ".*{{index .PromptResponses 0}}/(?P<branch>.*)";
                  valueFormat = "{{ .branch }}";
                  labelFormat = "{{ .branch | green }}";
                }
              ];
            }
            # Soft reset to upstream
            {
              key = "<f1>";
              command = "git reset --soft {{.CheckedOutBranch.UpstreamRemote}}";
              context = "files";
              prompts = [
                {
                  type = "confirm";
                  title = "Confirm:";
                  body = "Are you sure you want to reset HEAD to {{.CheckedOutBranch.UpstreamRemote}}?";
                }
              ];
            }
            # Push specific commit (and all preceding)
            {
              key = "<ctrl+shift+o>";
              command = "git push {{.SelectedRemote.RefName}} {{.SelectedLocalCommit.Sha}}:{{.SelectedLocalBranch.RefName}}";
              context = "commits";
              loadingText = "Pushing commit...";
              description = "Push a specific commit (and all preceding) commits";
            }
            # Create annotated tag
            {
              key = "N";
              description = "create annotated tag";
              command = "git tag -a {{index .PromptResponses 0}} -m \"{{index .PromptResponses 1}}\"";
              context = "tags";
              prompts = [
                {
                  type = "input";
                  title = "Annotated tag name:";
                }
                {
                  type = "input";
                  title = "Annotated tag message:";
                }
              ];
            }
            # Create GitHub PR (gh)
            {
              key = "<ctrl+r>";
              command = "gh pr create --fill --web";
              context = "global";
              loadingText = "Creating pull request on GitHub";
            }
            # View GitLab MR in browser
            {
              key = "G";
              command = "glab mr view -w {{.SelectedLocalBranch.UpstreamBranch}}";
              context = "localBranches";
              description = "Go to MR in gitlab";
              output = "log";
            }
            # Checkout PR by ID (hub)
            {
              key = "v";
              prompts = [
                {
                  type = "input";
                  title = "PR id:";
                }
              ];
              command = "hub pr checkout {{index .PromptResponses 0}}";
              context = "localBranches";
              loadingText = "checking out PR";
            }
            # Interactive GH PR selection checkout (gh)
            {
              key = "v";
              context = "localBranches";
              loadingText = "Checking out GitHub Pull Request...";
              command = "gh pr checkout {{.Form.PullRequestNumber}}";
              prompts = [
                {
                  type = "menuFromCommand";
                  title = "Which PR do you want to check out?";
                  key = "PullRequestNumber";
                  command = ''gh pr list --json number,title,headRefName,updatedAt --template '{{`{{range .}}{{printf "#%v: %s - %s (%s)" .number .title .headRefName (timeago .updatedAt)}}{{end}}`}}'';
                  filter = "#(?P<number>[0-9]+): (?P<title>.+) - (?P<ref_name>[^ ]+).*";
                  valueFormat = "{{.number}}";
                  labelFormat = ''{{"#" | black | bold}}{{.number | white | bold}} {{.title | yellow | bold}}{{" [" | black | bold}}{{.ref_name | green}}{{"]" | black | bold}}'';
                }
              ];
            }
            # Open git mergetool for selected file
            {
              key = "M";
              command = "git mergetool {{ .SelectedFile.Name }}";
              context = "files";
              loadingText = "Opening git mergetool";
              output = "log";
            }
            # Open git mergetool for repo
            {
              key = "<ctrl+e>";
              command = "git mergetool";
              context = "files";
              loadingText = "Opening git mergetool in the project repository";
              output = "log";
            }
            # Prune deleted remote branches
            {
              key = "<ctrl+e>";
              command = "git remote prune {{.SelectedRemote.Name}}";
              context = "remotes";
              loadingText = "Pruning...";
              description = "prune deleted remote branches";
            }
            # Prune merged local branches
            {
              key = "b";
              command = "git branch --merged master | grep -v '^[ *]*master$' | xargs -r git branch -d";
              context = "localBranches";
              loadingText = "Pruning...";
              description = "prune local branches that have been merged to master";
            }
            # Prune gone branches
            {
              key = "G";
              command = ''git fetch -p && for branch in $(git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | awk '$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'); do git branch -D $branch; done'';
              context = "localBranches";
              description = "Prune local branches no longer on its remote; (G)one.";
              loadingText = "Pruning gone...";
            }
            # Commit via Commitizen
            {
              key = "<ctrl+c>";
              context = "files";
              command = "git cz c";
              description = "commit with commitizen";
              loadingText = "opening commitizen commit tool";
              output = "terminal";
            }
            # Search history for expression
            {
              key = "<ctrl+a>";
              description = "Search the whole history for an expression in a file";
              command = "git checkout {{index .PromptResponses 3}}";
              context = "commits";
              prompts = [
                {
                  type = "input";
                  title = "Search word:";
                }
                {
                  type = "input";
                  title = "File/Subtree:";
                }
                {
                  type = "input";
                  title = "Ref:";
                  initialValue = "{{index .CheckedOutBranch.Name }}";
                }
                {
                  type = "menuFromCommand";
                  title = "Commits:";
                  command = "git log --oneline {{index .PromptResponses 2}} -S'{{index .PromptResponses 0}}' --all -- {{index .PromptResponses 1}}";
                  filter = "(?P<commit_id>[0-9a-zA-Z]*) *(?P<commit_msg>.*)";
                  valueFormat = "{{ .commit_id }}";
                  labelFormat = "{{ .commit_id | green | bold }} - {{ .commit_msg | yellow }}";
                }
              ];
            }
            # Fetch remote branch as new local
            {
              key = "<ctrl+f>";
              description = "fetch a remote branch as a new local branch";
              command = "git fetch {{index .SelectedRemote.Name }} {{index .PromptResponses 0}}:{{index .PromptResponses 1}}";
              context = "remotes";
              prompts = [
                {
                  type = "input";
                  title = "Remote Branch Name";
                  initialValue = "";
                }
                {
                  type = "input";
                  title = "New Local Branch Name";
                  initialValue = "";
                }
              ];
              loadingText = "fetching branch";
            }
            # Commit as non-default author
            {
              key = "<ctrl+c>";
              description = "commit as non-default author";
              command = "git commit -m \"{{index .PromptResponses 0}}\" --author=\"{{index .PromptResponses 1}} <{{index .PromptResponses 2}}>\"";
              context = "files";
              prompts = [
                {
                  type = "input";
                  title = "Commit Message";
                  initialValue = "";
                }
                {
                  type = "input";
                  title = "Author Name";
                  initialValue = "";
                }
                {
                  type = "input";
                  title = "Email Address";
                  initialValue = "";
                }
              ];
              loadingText = "commiting";
            }
            # Amend author of last commit
            {
              key = "<ctrl+a>";
              description = "amend the author of last commit";
              command = "git commit --amend --author=\"{{index .PromptResponses 0}} <{{index .PromptResponses 1}}>\"";
              context = "commits";
              prompts = [
                {
                  type = "input";
                  title = "Author Name";
                  initialValue = "";
                }
                {
                  type = "input";
                  title = "Email Address";
                }
              ];
              output = "terminal";
            }
            # tig blame (tree)
            {
              key = "b";
              command = "tig blame -- {{.SelectedFile.Name}}";
              context = "files";
              description = "blame file at tree";
              output = "terminal";
            }
            # tig blame (revision)
            {
              key = "b";
              command = "tig blame {{.SelectedSubCommit.Sha}} -- {{.SelectedCommitFile.Name}}";
              context = "commitFiles";
              description = "blame file at revision";
              output = "terminal";
            }
            # tig blame (tree from commitFiles)
            {
              key = "B";
              command = "tig blame -- {{.SelectedCommitFile.Name}}";
              context = "commitFiles";
              description = "blame file at tree";
              output = "terminal";
            }
            # tig show commit (subCommits)
            {
              key = "t";
              command = "tig show {{.SelectedSubCommit.Sha}}";
              context = "subCommits";
              description = "tig commit (t again to browse files at revision)";
              output = "terminal";
            }
            # tig show branch (local)
            {
              key = "t";
              command = "tig show {{.SelectedLocalBranch.Name}}";
              context = "localBranches";
              description = "tig branch (t again to browse files at revision)";
              output = "terminal";
            }
            # tig show branch (remote)
            {
              key = "t";
              command = "tig show {{.SelectedRemoteBranch.RemoteName}}/{{.SelectedRemoteBranch.Name}}";
              context = "remoteBranches";
              description = "tig branch (t again to browse files at revision)";
              output = "terminal";
            }
            # tig file history (commitFiles)
            {
              key = "t";
              command = "tig {{.SelectedSubCommit.Sha}} -- {{.SelectedCommitFile.Name}}";
              context = "commitFiles";
              description = "tig file (history of commits affecting file)";
              output = "terminal";
            }
            # tig file history (files)
            {
              key = "t";
              command = "tig -- {{.SelectedFile.Name}}";
              context = "files";
              description = "tig file (history of commits affecting file)";
              output = "terminal";
            }
            # Extract diff into index (squash patch approach)
            {
              key = "D";
              command = "git diff {{.SelectedLocalBranch.Name}} > /tmp/lazygit.patch && git reset --hard {{.SelectedLocalBranch.Name}} && git apply /tmp/lazygit.patch";
              context = "localBranches";
              description = "Extract diff into index";
            }
            # Add empty commit
            {
              key = "E";
              description = "Add empty commit";
              context = "commits";
              command = "git commit --allow-empty -m \"empty commit\"";
              loadingText = "Committing empty commit...";
            }
            # Pull from specific remote
            {
              key = "<ctrl+p>";
              description = "Pull from a specific remote repository";
              context = "files";
              loadingText = "Pulling ...";
              command = "git pull {{ .Form.Remote }} {{ .Form.RemoteBranch }}";
              prompts = [
                {
                  type = "input";
                  key = "Remote";
                  title = "Remote:";
                  suggestions = {
                    preset = "remotes";
                  };
                }
                {
                  type = "input";
                  key = "RemoteBranch";
                  title = "Remote branch:";
                  suggestions = {
                    command = "git branch --remote --list '{{.Form.Remote}}/*' --format='%(refname:short)' | sed 's/{{.Form.Remote}}\\///'";
                  };
                }
              ];
            }
            # Conventional commit helper
            {
              key = "<ctrl+v>";
              context = "global";
              description = "Create a new conventional commit";
              prompts = [
                {
                  type = "menu";
                  key = "Type";
                  title = "Type of change";
                  options = [
                    {
                      name = "feat";
                      description = "A new feature";
                      value = "feat";
                    }
                    {
                      name = "fix";
                      description = "A bug fix";
                      value = "fix";
                    }
                    {
                      name = "chore";
                      description = "Other changes that don't modify src or test files";
                      value = "chore";
                    }
                    {
                      name = "docs";
                      description = "Documentation only changes";
                      value = "docs";
                    }
                    {
                      name = "refactor";
                      description = "A code change that neither fixes a bug nor adds a feature";
                      value = "refactor";
                    }
                    {
                      name = "test";
                      description = "Adding missing tests or correcting existing tests";
                      value = "test";
                    }
                    {
                      name = "build";
                      description = "Changes that affect the build system or external dependencies";
                      value = "build";
                    }
                    {
                      name = "ci";
                      description = "Changes to CI configuration files and scripts";
                      value = "ci";
                    }
                    {
                      name = "perf";
                      description = "A code change that improves performance";
                      value = "perf";
                    }
                    {
                      name = "revert";
                      description = "Reverts a previous commit";
                      value = "revert";
                    }
                    {
                      name = "style";
                      description = "Changes that do not affect the meaning of the code";
                      value = "style";
                    }
                  ];
                }
                {
                  type = "input";
                  title = "Scope";
                  key = "Scope";
                  initialValue = "";
                }
                {
                  type = "menu";
                  title = "Breaking change? (Adding '!')";
                  options = [
                    {
                      name = "Non-breaking";
                      description = "A non-breaking change";
                      value = "";
                    }
                    {
                      name = "Breaking";
                      description = "A breaking change";
                      value = "!";
                    }
                  ];
                  key = "Breaking";
                }
                {
                  type = "input";
                  title = "Message";
                  key = "Message";
                  initialValue = "";
                }
              ];
              command = "git commit --message '{{.Form.Type}}{{ if .Form.Scope }}({{ .Form.Scope }}){{ end }}{{.Form.Breaking}}: {{.Form.Message}}'";
              loadingText = "Creating a conventional commit...";
            }
            # Disentangle (squash & rebase)
            {
              key = "K";
              description = "Disentangle: Squash all changes into a single commit and rebase onto the selected branch";
              context = "localBranches";
              command = ''
                #!/bin/bash
                BASE_BRANCH="{{.SelectedLocalBranch.Name}}"
                if [[ -n $(git status --porcelain) ]]; then
                  echo "Error: Working tree is dirty. Please commit or stash your changes before running this script."
                  exit 1
                fi
                merge_base=$(git merge-base $BASE_BRANCH HEAD)
                first_commit_hash=$(git rev-list --reverse $merge_base..HEAD | head -n 1)
                first_commit_message=$(git log -1 --format=%B $first_commit_hash)
                git reset $merge_base
                git add -A
                GIT_AUTHOR_NAME="$(git log -1 --format='%an' $first_commit_hash)" \
                GIT_AUTHOR_EMAIL="$(git log -1 --format='%ae' $first_commit_hash)" \
                git commit -m "$first_commit_message"
                git rebase $BASE_BRANCH'';
            }
          ];
          #       git add -A
          #       # Create a new commit with all the changes, using the first commit's message and author
          #       GIT_AUTHOR_NAME="$(git log -1 --format='%an' $first_commit_hash)" \
          #       GIT_AUTHOR_EMAIL="$(git log -1 --format='%ae' $first_commit_hash)" \
          #       git commit -m "$first_commit_message"
          #       # Rebase onto the base branch
          #       git rebase $BASE_BRANCH

        };
      };
    };

  ren.aspects.vcs.abbreviations =
    { pkgs, ... }:
    let
      inherit (addax) getExeName;
    in
    with pkgs;
    {
      lg = "${getExeName lazygit}";
    };
}
