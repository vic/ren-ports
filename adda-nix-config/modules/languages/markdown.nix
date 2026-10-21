# markdown: LSP, previewer and editor wiring for Markdown.
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.languages-markdown =
    # { pkgs, ... }:
    # let
    #   extraPackages = with pkgs; [
    #     marksman
    #   ];
    # in
    {
      homeManager =
        { pkgs, ... }:
        {
          home.packages = with pkgs; [
            marksman # LSP for Markdown.
            glow # Markdown previewer in terminal.
            typos-lsp # Spellcheck LSP; referenced by `helixLanguages` below.
          ];
        };

      helixLanguages =
        { pkgs, ... }:
        {
          language = [
            {
              name = "markdown";
              language-servers = [ (addax.getExeName pkgs.typos-lsp) ];
            }
          ];
        };

      # helixExtraPackages = extraPackages;
      # zedEditorExtraPackages = extraPackages;
      zed-extensions = { ... }: [ "markdown-oxide" ];
      vscodium-extensions =
        { ... }:
        [
          "yzhang.markdown-all-in-one"
        ];
    };

}
