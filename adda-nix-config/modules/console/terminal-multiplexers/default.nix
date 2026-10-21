# terminal multiplexers: screen, tmux, zellij
{ ren, ... }:
{
  ren.aspects.console-terminalMultiplexers = {
    # Terminal multiplexers (screen, tmux, zellij).

    includes = with ren.aspects; [
      console-terminalMultiplexers-screen
      console-terminalMultiplexers-tmux
      console-terminalMultiplexers-zellij
    ];
  };
}
