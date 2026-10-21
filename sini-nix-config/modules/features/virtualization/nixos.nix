# CONSUME: layer the host-side GPU/passthrough overlay on top of the guest configs delivered into
# microvm.vms.<name>.config: facter-derived PCI passthrough devices, the ro-store share, state shares,
# root keys, and host-side systemd ExecCondition vfio gates.
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
  gpu = ren.helpers.gpuPassthrough;
  roStoreShare = {
    source = "/nix/store";
    mountPoint = "/nix/.ro-store";
    tag = "ro-store";
    proto = "virtiofs";
  };
in
{
  ren.aspects.virtualization-microvm-host-nixos.nixos =
    {
      host,
      config,
      pkgs,
      resolved-users,
      ...
    }:
    let
      facter = config.facter.report;

      # M1: SSH keys for VM root access, from admins/wheel members (resolved-users channel pool).
      rootKeys = lib.concatMap (
        u:
        lib.optionals (builtins.any (g: g == "admins" || g == "wheel") (map (g: g.name) u.groups)) u.sshKeys
      ) resolved-users;

      guests = map (vm: {
        inherit (vm) name;
        recs = gpu.resolvePassthrough vm.microvm.passthrough facter;
        sharedNixStore = host.virtualization-microvm-host.sharedNixStore;
      }) host.guests;

      # A guest's root is a tmpfs, so its impermanence binds persist nothing unless /persist and /cache
      # are real. Each guest gets its own directory under the host's matching volume.
      stateVolumes = lib.filter (v: config.environment.persistence ? ${v}) [
        "/persist"
        "/cache"
      ];
      stateDir =
        name: volume: "${config.environment.persistence.${volume}.persistentStoragePath}/microvms/${name}";
      stateShares =
        name:
        map (volume: {
          source = stateDir name volume;
          mountPoint = volume;
          tag = "state${lib.replaceStrings [ "/" ] [ "-" ] volume}";
          proto = "virtiofs";
        }) stateVolumes;
    in
    {
      microvm.vms = lib.mkMerge (
        map (g: {
          ${g.name}.config = {
            microvm.devices = gpu.toMicrovmDevices g.recs;
            microvm.shares = lib.optional g.sharedNixStore roStoreShare ++ stateShares g.name;
            # The host's store, read-only: the host collects it, the guest cannot.
            nix.gc.automatic = lib.mkIf g.sharedNixStore (lib.mkForce false);
            # Mounted in the initrd, before impermanence binds from them.
            fileSystems = lib.genAttrs stateVolumes (_: {
              neededForBoot = true;
            });
            users.users.root.openssh.authorizedKeys.keys = rootKeys;
          };
        }) guests
      );

      systemd.tmpfiles.rules = lib.concatMap (
        g: map (volume: "d ${stateDir g.name volume} 0700 root root -") stateVolumes
      ) guests;

      # Host-side gate: hold the VM's start units until the passed-through PCI device is on vfio-pci.
      systemd.services = lib.mkMerge (
        map (
          g:
          lib.optionalAttrs (g.recs != [ ]) (
            let
              gate = gpu.mkVfioGate pkgs g.recs;
            in
            {
              "microvm@${g.name}".serviceConfig.ExecCondition = gate;
              "microvm-pci-devices@${g.name}".serviceConfig.ExecCondition = gate;
            }
          )
        ) guests
      );

      # No host-side guest networking here: guest taps match `vm-*` into br0 in core.network.networking.
    };
}
