# vcs: oyui merge/diff TUI package and config
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.vcs.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        (addax.omni pkgs).unified.oyui.packages.default
      ];

      xdg.configFile."oyui/config.rn".source = pkgs.writeText "oyui-config.rn" /* rn */ ''
        // Rune language documentation at: https://rune-rs.github.io/
        pub fn config() {
          // Oyui comes with 40+ built-in themes out of the box:
          // aura, ayu, catppuccin-mocha, dracula, gruvbox-dark, nord,
          // one-dark, everforest-light...
          //
          // Full list at:
          // https://github.com/emilien-jegou/oyui/tree/main/docs/themes.md
          theme::set("nightowl-dark");

          // Overwritting theme specific config.

          // 50+ actions and settings to configure, check the documentation:
          // https://github.com/emilien-jegou/oyui/wiki/Actions-API
          // theme::bg::set("#000000");
          // theme::file_staged_highlight::set(LineHighlightMode::Gradient(0.05));

          // You can nest config per view with on_mode:
          // on_mode("file", || {
          //   // keybind can take modifiers: "ctrl", "shift" or "alt"
          //   keybind("ctrl-j", || view::file::cursor::down(5));
          //   keybind("ctrl-k", || view::file::cursor::up(5));
          // });

          // on_mode("tree", || {
          //   keybind("ctrl-j", || view::tree::cursor::down(5));
          //   keybind("ctrl-k", || view::tree::cursor::up(5));
          // });

          global::confirm_merge_window_enabled::set(true);
        }
      '';
    };
}
