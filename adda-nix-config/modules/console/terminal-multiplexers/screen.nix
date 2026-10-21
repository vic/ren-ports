# screen: GNU Screen
{ ren, ... }:
{
  ren.aspects.console-terminalMultiplexers-screen = {
    # GNU Screen.

    homeManager = {
      programs.screen = {
        enable = true;
        screenrc = ''
          defscrollback 10000
          startup_message off
        '';
      };
    };
  };
}
