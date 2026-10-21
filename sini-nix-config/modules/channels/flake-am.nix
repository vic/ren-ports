# a-m channels, flake: flake inputs, any -> fleet (flake-file).
{ ren, ... }:
{
  ren.channels.flake-inputs = {
    fold = ren.lib.fold.attrs;
    to = _: ren.kinds.fleet;
    into = { ... }: inputs: { flake-file.inputs = inputs; };
  };
}
