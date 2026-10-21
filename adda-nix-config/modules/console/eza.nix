# eza: ls replacement and its ls/l/... aliases
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  # A modern replacement for ‘ls’. Split out of `console` so headless hosts that take
  #  `shells` without the full console toolkit still get it: the ls/l/… aliases below
  #  call `eza` by name, so they only work where this aspect is included.
  ren.aspects.console-eza.homeManager = {
    programs.eza = {
      enable = true;

      icons = "auto";
      git = true;
      colors = "auto";
      extraOptions = [
        "--all"
        "--long"
        "--header"
        "--group-directories-first"
        "--classify"
        "--sort=newest"
        "--git"
        "--color-scale=all"
        "--octal-permissions"
      ];
    };
  };

  ren.aspects.console-eza.aliases =
    { pkgs, ... }:
    let
      inherit (addax) getExeName;
    in
    with pkgs;
    {
      # Aliases for ls.
      #ls = "ls --no-group --classify --human-readable --all --color" # "ls -GFha --color"
      ls = "${getExeName eza} --all --color=auto --classify --group-directories-first --sort=newest --icons";
      #l = "ls -l --human-readable --all --color" # "ls -lah --color"
      l = "${getExeName eza} --all --long --git --header --color=auto --group-directories-first --classify --color-scale=all --sort=newest --icons=auto --octal-permissions";
      lsn = "${getExeName eza} --all --long --git --header --color=auto --classify --color-scale=all --sort=newest --icons=auto";
      lso = "${getExeName eza} --all --long --git --header --color=auto --classify --color-scale=all --sort=oldest --icons=auto";
      lst = "${getExeName eza} --tree --all --color=auto --classify --color-scale=all --icons=auto";
      lstl = "${getExeName eza} --tree --long --git --header --all --color=auto --classify --color-scale=all --icons=auto --octal-permissions";
      "l." = "${getExeName eza} -a | egrep '^\.'";
      #alias lr='ls -tRFh'   #sorted by date,recursive,show type,human readable
      #alias lS='ls -1FSsh'
    };
}
