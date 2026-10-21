# generate: `nix run .#generate-files` writes every generated file and flake.nix.
{ ren, inputs, ... }:
{
  ren.aspects.files-generate = {
    at = ren.system.x86_64-linux;
    packages =
      { system, ... }:
      let
        inherit (inputs.nixpkgs) lib;
        pkgs = system.legacyPackages;
        self = inputs.self.packages.${system.name};
        description = "Generate all automatically generated files for this repository";
      in
      {
        generate-files = pkgs.writeShellApplication {
          name = "generate-files";
          meta.description = description;
          text = ''
            # github:sini/files.
            ${lib.getExe self.write-files}

            lock_bck=$(mktemp)
            cp -p flake.lock "$lock_bck"

            ${lib.getExe self.write-flake}

            # If flake.lock remains unchanged, restore mtime.
            if cmp -s flake.lock "$lock_bck"; then
              touch -r "$lock_bck" flake.lock
            fi
          '';
        };
      };
  };
}
