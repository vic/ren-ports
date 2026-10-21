# a-m channels, darwin: homebrew casks. homebrew-mas dropped (no emitter, layout VERIFY).
{ ren, ... }:
{
  ren.channels.homebrew-cask = {
    fold = ren.lib.fold.list;
    to = e: ren.lib.upTo ren.kinds.mac e;
    into = { ... }: casks: { darwin.homebrew.casks = casks; };
  };
}
