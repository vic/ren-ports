# third file of dev-editor-nvf: languages explicitly disabled.
{ ... }:
{
  ren.aspects.dev-editor-nvf.homeManager.programs.nvf.settings.vim.languages = {
    assembly.enable = false;
    astro.enable = false;
    nu.enable = false;
    csharp.enable = false;
    julia.enable = false;
    vala.enable = false;
    scala.enable = false;
    r.enable = false;
    gleam.enable = false;
    dart.enable = false;
    ocaml.enable = false;
    elixir.enable = false;
    haskell.enable = false;
    ruby.enable = false;
    svelte.enable = false;
  };
}
