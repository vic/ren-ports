# readme dirs (a fn of vocabDirs): live table of modules/ directories, checked against docs/_vocabulary-dirs.nix.
{ vocabDirs }:
let
  inherit (builtins)
    attrNames
    concatStringsSep
    filter
    readDir
    ;
  dirsOf = p: filter (n: (readDir p).${n} == "directory") (attrNames (readDir p));
  described = import ./_described.nix "_vocabulary-dirs.nix";
in
''
  import-tree loads every `.nix` file under `modules/`. Paths with `/_` are skipped.
  Dir names are for humans only. Ren does not read them.

  ${concatStringsSep "\n" (
    [
      "| dir | purpose |"
      "| --- | --- |"
    ]
    ++ map (n: "| `modules/${n}/` | ${vocabDirs.${n}} |") (described "modules" (dirsOf ./..) vocabDirs)
  )}
''
