{
  description = "My-project build environment";
  nixConfig.zsh-prompt = "[nix(my-project)] ";
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
  };

  outputs =
    { nixpkgs }:
    let
      inherit (nixpkgs.legacyPackages.x86_64-linux) pkgs;
      fooScript = pkgs.writeScriptBin "foo.sh" ''
        #!/usr/bin/env sh
        echo $FOO
      '';
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        name = "My-project build environment";
        buildInputs = [
          pkgs.python3
          fooScript
        ];
        shellHook = ''
          echo "Welcome in $name"
          export FOO="BAR"
        '';
      };
    };
}
