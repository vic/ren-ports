# channels n-z, storage: persist dirs/files; entries are { directories; files; }. (cache/cacheHome are a-m.)
{ ren, lib, ... }:
let
  inherit (ren.lib) upTo;
  merge = es: {
    directories = lib.unique (builtins.concatMap (e: e.directories or [ ]) es);
    files = lib.unique (builtins.concatMap (e: e.files or [ ]) es);
  };
  pathOf = f: f.file or f.filePath or f;
  # sini cortex-cuda-unpersist-pinned: a guest drops the files/prefixes its `unpersist` field lists.
  unpersist =
    guest: es:
    let
      u = if guest == null then { } else guest.unpersist;
      files = u.files or [ ];
      prefixes = u.filePrefixes or [ ];
      pinned = f: builtins.elem (pathOf f) files || lib.any (p: lib.hasPrefix p (pathOf f)) prefixes;
    in
    map (e: e // { files = lib.filter (f: !pinned f) (e.files or [ ]); }) es;
in
{
  ren.channels.persist = {
    fold = ren.lib.fold.list;
    to = e: upTo ren.kinds.host e;
    into =
      { ... }@args:
      es:
      {
        nixos.environment.persistence."/persist" = merge (unpersist (args.guest or null) es);
      };
  };

  ren.channels.persistHome = {
    fold = ren.lib.fold.list;
    at = ren.kinds.user;
    to = e: e;
    into = { user, ... }: es: { homeManager.home.persistence."/persist" = merge es; };
  };
}
