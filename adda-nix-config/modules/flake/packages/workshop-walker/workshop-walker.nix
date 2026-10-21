# workshop-walker: flake package (RimWorld workshop browser).
{ ren, ... }:
{
  ren.aspects.pkg-workshop-walker = {
    at = ren.system.x86_64-linux;
    packages =
      { system, ... }:
      let
        pkgs = system.legacyPackages;
      in
      {
        workshop-walker = pkgs.callPackage ./_package.nix {
          # nixpkgs' source-built rustc 1.98 links LLVM 21, whose AVX-512 VNNI intrinsic signatures mismatch its
          # stdarch ("intrinsic signature mismatch" in `diskann-vector`). The upstream binaries bundle their own LLVM.
          rustPlatform = pkgs.makeRustPlatform { inherit (pkgs.rust.packages.prebuilt) cargo rustc; };
        };
      };
  };
}
