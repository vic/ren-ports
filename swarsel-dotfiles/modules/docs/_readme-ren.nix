# readme ren (a fn of ren): the Ren part of the README, from live Ren data. A renamed or new kind, channel,
# class or directory without a vocabulary line is an eval error (_described.nix).
{ ren }:
let
  inherit (builtins)
    attrNames
    attrValues
    concatStringsSep
    filter
    readDir
    ;
  v = import ./_vocabulary.nix;
  table =
    file: what: head: names: lines:
    concatStringsSep "\n" (
      [
        "| ${head} | purpose |"
        "| --- | --- |"
      ]
      ++ map (n: "| `${n}` | ${lines.${n}} |") (import ./_described.nix file what names lines)
    );
  dirsOf = p: filter (n: (readDir p).${n} == "directory") (attrNames (readDir p));
  q = l: ''"${l}"'';
  machines = k: shape: map (m: "  ${k}_${m.name}${shape (q m.name)}") (attrValues ren.${k});
  guestEdges = map (g: "  host_${g.on.name} --> guest_${g.name}") (attrValues ren.guest);
  diagram = concatStringsSep "\n" (
    [
      "```mermaid"
      "flowchart LR"
    ]
    ++ machines "host" (l: "[${l}]")
    ++ machines "guest" (l: "[[${l}]]")
    ++ machines "mac" (l: "(${l})")
    ++ machines "home" (l: "[/${l}/]")
    ++ machines "droid" (l: "{{${l}}}")
    ++ guestEdges
    ++ [ "```" ]
  );
in
''
  ## Ren

  This repository is written in [Ren](https://github.com/vic/ren), a small language for aspect-oriented,
  context-driven Nix fleets built on [Gen](https://github.com/sini/gen).
  Generated part: edit `modules/docs/`, then run `nix run .#write-readme`.

  ```sh
  nix eval --raw .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
  nix run .#write-readme    # regenerate this README
  nix run .#write-flake     # regenerate flake.nix from the flake-inputs channel
  ```

  ### Machines

  Generated from `ren.host`, `ren.guest`, `ren.mac`, `ren.home` and `ren.droid`: `[host]`, `[[guest]]`, `(mac)`,
  `[/home/]`, `{{droid}}`. A guest runs on its host.

  ${diagram}

  ### Kinds

  ${table "_vocabulary.nix" "kinds" "kind" (attrNames ren.kinds) v.kinds}

  ### Channels

  ${table "_vocabulary.nix" "channels" "channel" (attrNames ren.channels) v.channels}

  ### Classes

  ${table "_vocabulary.nix" "classes" "class" (attrNames ren.classes) v.classes}

  ### Directory structure

  import-tree loads every `.nix` file under `modules/`. Paths with `/_` are skipped.
  Directory names are for humans only. Ren does not read them.

  ${table "_vocabulary.nix" "dirs" "dir" (dirsOf ./..) v.dirs}
''
