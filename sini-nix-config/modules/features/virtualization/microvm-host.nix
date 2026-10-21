{ ren, lib, inputs, ... }:
{
  ren.aspects.virtualization-microvm-host = {
    nixos = {
      imports = [ inputs.microvm.nixosModules.host ];

      microvm.host.enable = true;

      users.users.microvm.extraGroups = [ "disk" ];
    };

    firewall = {
      networking.firewall.allowedUDPPorts = [ 67 ];
    };

    persist.directories = [
      {
        directory = "/var/lib/microvms";
        user = "microvm";
        group = "kvm";
        mode = "0775";
      }
    ];
  };

  # Per-guest entity contract read by the host-side GPU overlay (gpu-claims.nix).
  # microvm.passthrough lives on kind guest (topology/guest.nix); sharedNixStore is declared here on machine.
  ren.kinds.guest.unpersist = ren.lib.opt (lib.types.submodule {
    options.files = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
    options.filePrefixes = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
  }) { };

  ren.kinds.machine.virtualization-microvm-host = ren.lib.opt (lib.types.submodule {
    options.sharedNixStore = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Auto-share the host nix store into guests over virtiofs.";
    };
  }) { };
}
