# tmux: tmux
{ ren, ... }:
{
  ren.aspects.console-terminalMultiplexers-tmux = {
    # tmux.

    homeManager = {
      programs.tmux = {
        enable = true;
      };
    };
  };
}
