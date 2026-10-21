{ inputs, ... }:
{
  ren.aspects.dev-lang-rust = {
    nixpkgs-overlays = [ inputs.fenix.overlays.default ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.fenix.complete.withComponents [
            "cargo"
            "clippy"
            "rust-src"
            "rustc"
            "rustfmt"
          ])
          pkgs.rust-analyzer-nightly
          pkgs.cargo-edit
          pkgs.wasm-pack
          pkgs.wasm-bindgen-cli
        ];
      };
  };
}
