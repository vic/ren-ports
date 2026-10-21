# a-m channels, storage: cache dirs/files; entries are { directories; files; }. (persist/persistHome are N-Z.)
{ ren, ... }:
let
  inherit (ren.lib) upTo;
  merge = es: {
    directories = builtins.concatMap (e: e.directories or [ ]) es;
    files = builtins.concatMap (e: e.files or [ ]) es;
  };
in
{
  ren.channels.cache = {
    fold = ren.lib.fold.list;
    to = e: upTo ren.kinds.host e;
    into = { ... }: es: { nixos.environment.persistence."/cache" = merge es; };
  };

  ren.channels.cacheHome = {
    fold = ren.lib.fold.list;
    at = ren.kinds.user;
    to = e: e;
    into = { user, ... }: es: { homeManager.home.persistence."/cache" = merge es; };
  };
}
