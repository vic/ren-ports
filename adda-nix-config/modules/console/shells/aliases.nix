# shells: common aliases and abbreviations
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.shells-aliasesAbbreviations.aliases =
    { pkgs, ... }:
    let
      inherit (addax) getExeName;
    in
    with pkgs;
    {
      mv = "mv --interactive";
      ln = "ln --interactive";
      xcp = "${getExeName xcp} --interactive";
      mkdir = "mkdir --verbose";
      cat = "${getExeName bat} --pager \"never\"";

      ncdu = "${getExeName ncdu} --extended -2 --color dark";
    };
  ren.aspects.shells-aliasesAbbreviations.abbreviations =
    { pkgs, ... }:
    let
      inherit (pkgs) lib;
      inherit (addax) getExeName getExeName';

      # Upwards navigation: `..` -> `z ../`, `...` ->`z ../../`, ...
      # `maxDots` is the largest number of dots to generate, starting from 2.
      dotAbbreviations =
        maxDots:
        lib.genAttrs (map (dots: lib.strings.replicate dots ".") (lib.range 2 maxDots)) (
          dots: "z " + lib.strings.replicate (lib.stringLength dots - 1) "../"
        );
    in
    with pkgs;
    {
      cpp = "${lib.getExe' wl-clipboard "wl-copy"} !!";
      ee = "exec";

      # Navigation.
      u = "go-up-directories";
      br = "${getExeName broot}";

      # Confirm before overwriting something.
      cp = "${getExeName xcp}";
      rm = "${getExeName gomi}";
      # rm = "rm --interactive";

      o = "xdg-open";

      md = "mkdir --parents";
      rmd = "rm --recursive";

      # k = "kubectl";
      urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
      urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
      e = "exit";
      ":q" = "exit";
      ":x" = "exit";
      lj = "${getExeName lazyjournal}";
      y = "${getExeName yazi}";
      b = "${getExeName btop}";

      # Working with temporary files and directories.
      tmpdir = "pushd \$(mktemp -d)";
      td = "tmpdir";
      pd = "popd";

      fe = "fzf-open-edit";
      d = "xdg-open (tv files)";
      s = "xdg-open (tv text | string split ':' | head -n 1)";

      sshl = "${getExeName lazyssh}";
      frj = "${getExeName firejail}";

      path-list = "echo $PATH | ${getExeName' coreutils-full "tr"} ' ' '\n'";

      cd = "z";
      cdi = "zi";
      zb = "z -";
      f = "zi";
      ff = "z";
      fff = "z -";
      fb = "z -";
    }
    // dotAbbreviations 10
  # // lib.foldl (val: lib.mergeAttrs val.abbreviations or { }) { } cli;
  ;
  # builtins.removeAttrs aliases []
  # abbreviationsGlobal = {
  #   G = "| grep";
  #   L = "| less -R";
  # };
}
