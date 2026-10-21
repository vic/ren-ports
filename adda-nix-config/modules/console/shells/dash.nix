# dash: dash hands off to nushell
{ ren, ... }:
{
  ren.aspects.shells-dash.homeManager = {
    xdg.configFile."dashrc".text = /* dash */ ''
      # Ensure that e.g. tramp doesn't try to launch nu.
      if ! [ "$TERM" = "dumb" ]; then
          # Disable C-s freezing the terminal
          stty -ixon

          exec nu
          # exec fish
      fi
    '';
    home.sessionVariables.ENV = "$HOME/.config/dashrc";
  };
}
