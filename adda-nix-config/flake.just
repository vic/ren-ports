alias u := update
update *ARGS:
  nix flake update {{ARGS}}

alias c := check
[default]
check *ARGS:
  nix flake check {{ARGS}}

alias s := show
show *ARGS:
  nix flake show {{ARGS}}
