{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    nixpkgs-stable.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.zst";
  };

  outputs =
    { flake-utils, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages."${system}";

        base =
          { modulesPath, ... }:
          {
            imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

            virtualisation = {
              graphics = false;

              host = { inherit pkgs; };
            };
          };

        machine = nixpkgs.lib.nixosSystem {
          system = builtins.replaceStrings [ "darwin" ] [ "linux" ] system;

          modules = [
            base
            ./module.nix
          ];
        };

        program = pkgs.writeShellScript "run-vm.sh" ''
          export NIX_DISK_IMAGE=$(mktemp -u -t nixos.qcow2)

          trap "rm -f $NIX_DISK_IMAGE" EXIT

          ${machine.config.system.build.vm}/bin/run-nixos-vm
        '';

      in
      {
        packages = { inherit machine; };

        apps.default.program = "${program}";

      }
    );
}
