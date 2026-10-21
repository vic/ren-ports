# Large commented-out alternative config (sesh/stylix) in sini source not carried over.
{ ... }:
{
  ren.aspects.dev-mux-tmux.homeManager =
    { pkgs, ... }:
    {
      programs.tmux = {
        enable = true;
        sensibleOnTop = true;
        terminal = "tmux-256color";
        shortcut = "a";
        keyMode = "vi";
        customPaneNavigationAndResize = true;
        baseIndex = 1;
        plugins = with pkgs.tmuxPlugins; [
          extrakto
          cpu
          weather
          battery
          vim-tmux-navigator
          tmux-window-name
        ];
        extraConfig = ''
          set -ga terminal-overrides ",*:Tc"
        '';
      };
    };
}
