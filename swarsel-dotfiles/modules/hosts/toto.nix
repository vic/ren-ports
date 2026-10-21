# toto: old hosts/utility/toto/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.host.toto = {
    system = ren.system.x86_64-linux;
    isImpermanence = true;
  };
  ren.aspects.toto.at = ren.host.toto;
  # old full-build-only imports
  ren.aspects.toto-full = {
    at = and [
      ren.host.toto
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.profile-minimal
    ];
  };
  ren.aspects.toto.nixos =
    {
      variant,
      config,
      lib,
      ...
    }:
    {

      imports = [
        ../../hosts/utility/toto/disk-config.nix
        ../../hosts/utility/toto/hardware-configuration.nix
      ]
      ++ lib.optionals (!variant.minimal) [
      ];

      swarselsystems = {
        info = "~SwarselSystems~ remote install helper";
        isBtrfs = true;
        isCrypted = false;
        isLaptop = false;
        isLinux = true;
        isSecureBoot = false;
        isSwap = true;
        rootDisk = "/dev/vda";
        swapSize = "2G";
        wallpaper = sw.root "files/wallpaper/landscape/lenovowp.png";
      };

      topology.self.interfaces.bootstrapper = { };
      sops.secrets.toto-deploy-test.sopsFile = config.node.secretsDir + "/secret.yaml";

      networking = {
        firewall.enable = false;
        hostName = "toto";
      };

      node.lockFromBootstrapping = lib.mkForce false;

    };
}
