# hotel: old hosts/utility/hotel/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and anyOf within;
  # old utility host: one config per arch, named `<name>` on x86_64-linux and `<name>-<arch>` elsewhere
  hotels = anyOf [
    ren.host.hotel
    ren.host.hotel-aarch64-linux
  ];
  sw = ren.helpers;
in
{
  ren.host.hotel = {
    system = ren.system.x86_64-linux;
    isImpermanence = true;
  };
  ren.host.hotel-aarch64-linux = {
    system = ren.system.aarch64-linux;
    configName = "hotel";
    isImpermanence = true;
  };
  ren.aspects.hotel.at = hotels;
  # old full-build-only imports
  ren.aspects.hotel-full = {
    at = and [
      hotels
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.niri
      ren.aspects.noctalia
      ren.aspects.profile-public
    ];
  };
  ren.aspects.hotel.nixos =
    {
      variant,
      machine,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mainUser = "demo";
    in
    {

      imports = [
        ../../hosts/utility/hotel/hardware-configuration.nix
        ../../hosts/utility/hotel/disk-config.nix
        {
          _module.args.diskDevice = config.swarselsystems.rootDisk;
        }
      ]
      ++ lib.optionals (!variant.minimal) [
      ]
      ++ lib.optionals (!variant.minimal) (
        builtins.attrValues (
          lib.getAttrs [
          ] { }
        )
      );

      swarselsystems = {
        inherit mainUser;
        info = "~SwarselSystems~ demo host";
        isBtrfs = false;
        isCrypted = true;
        isLinux = true;
        isPublic = true;
        isSecureBoot = false;
        isSwap = true;
        rootDisk = "/dev/vda";
        swapSize = "4G";
        wallpaper = sw.root "files/wallpaper/landscape/lenovowp.png";
      };

      topology.self.interfaces."demo host" = { };

      services = {
        printing.drivers = lib.mkIf (machine.system.name != "x86_64-linux") (lib.mkForce [ ]);
        qemuGuest.enable = true;
      };

      boot = {
        kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot.enable = lib.mkForce true;
        };
      };

      environment.variables.WLR_RENDERER_ALLOW_SOFTWARE = 1;
      hardware.graphics.enable32Bit = lib.mkIf (machine.system.name != "x86_64-linux") (lib.mkForce false);

      networking = {
        firewall.enable = true;
        hostName = "hotel";
      };

      nixpkgs.overlays = lib.mkAfter [ (_: prev: { niri-stable = prev.niri; }) ];

    };
}
