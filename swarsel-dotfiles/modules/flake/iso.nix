# installer images (live ISO, keygen, kexec): plain NixOS evaluations of hosts/utility modules, per system
{ ren, inputs, ... }:
let
  self = inputs.self;
in
{
  ren.aspects.iso.flake-inputs = {
    nixos-generators = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nixos-generators";
    };

    nixos-images.url = "github:Swarsel/nixos-images/main";
    smallpkgs.url = "github:nixos/nixpkgs/08fcb0dcb59df0344652b38ea6326a2d8271baff?narHash=sha256-HXIQzULIG/MEUW2Q/Ss47oE3QrjxvpUX7gUl4Xp6lnc%3D";
  };

  ren.aspects.iso.at = ren.kinds.system;
  ren.aspects.iso.packages =
    { system, ... }:
    let
      pkgs = system.legacyPackages;
      sys = system.name;
    in
    {
        keygen = inputs.nixos-generators.nixosGenerate {
          inherit pkgs;
          system = sys;
          format =
            {
              aarch64-linux = "sd-aarch64-installer";
              x86_64-linux = "install-iso";
            }
            .${sys};
          modules = [
            inputs.home-manager.nixosModules.home-manager
            "${self}/hosts/utility/policestation"
          ];
        };
        # nix build --print-out-paths --no-link .#live-iso
        live-iso = inputs.nixos-generators.nixosGenerate {
          inherit pkgs;
          system = sys;
          format =
            {
              aarch64-linux = "sd-aarch64-installer";
              x86_64-linux = "install-iso";
            }
            .${sys};
          modules = [
            inputs.home-manager.nixosModules.home-manager
            "${self}/hosts/utility/drugstore"
          ];
          specialArgs = {
            inherit self;
            inherit (self.swarselsystemsLib) root;
          };
        };
        # nix build --print-out-paths --no-link .#pnap-kexec --system <system>
        swarsel-kexec =
          (inputs.smallpkgs.legacyPackages.${sys}.nixos [
            {
              imports = [ "${self}/hosts/utility/brickroad" ];
              _file = __curPos.file;
              system.kexec-installer.name = "swarsel-kexec";
            }
            inputs.nixos-images.nixosModules.kexec-installer
          ]).config.system.build.kexecInstallerTarball;

    };
}
