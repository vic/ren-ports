# gen-lsp: input only; its source builds pkgs/by-name/gen-lsp-mcp (threaded as `gen-lsp-src` by the overlay).
{ ren, ... }:
{
  ren.aspects.flake-gen-lsp = {
    at = ren.kinds.fleet;
    flake-inputs =
      { ... }:
      {
        gen-lsp = {
          url = "github:sini/gen-lsp";
          inputs.nixpkgs.follows = "nixpkgs-unstable";
        };
      };
  };
}
