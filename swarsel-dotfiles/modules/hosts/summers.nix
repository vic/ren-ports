# summers: old hosts/nixos/x86_64-linux/summers/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.host.summers = {
    system = ren.system.x86_64-linux;
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers.at = ren.host.summers;
  ren.aspects.summers.includes = [
    ren.aspects.microvm-host
    ren.aspects.systemd-networkd-server-home
  ];
  # old full-build-only imports
  ren.aspects.summers-full = {
    at = and [
      ren.host.summers
      (within ren.variant.full)
    ];
    includes = [
      ren.aspects.opkssh
      ren.aspects.podman
      ren.aspects.profile-localserver
      ren.aspects.restic
      ren.aspects.smartctl-exporter
      ren.aspects.wireguard
      ren.aspects.zfs-exporter
    ];
  };
  ren.guest.summers-ankisync = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "ankisync";
    withZfs = true; 
  };
  ren.guest.summers-atuin = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "atuin";
    withZfs = true; 
  };
  ren.guest.summers-audio = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "audio";
     eternorPaths = [ "Music" ]; withZfs = true; 
  };
  ren.guest.summers-firefly = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "firefly";
    withZfs = true; 
  };
  ren.guest.summers-forgejo = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "forgejo";
    withZfs = true; 
  };
  ren.guest.summers-freshrss = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "freshrss";
    withZfs = true; 
  };
  ren.guest.summers-homebox = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "homebox";
    withZfs = true; 
  };
  ren.guest.summers-immich = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "immich";
     eternorPaths = [ "Pictures" ]; withZfs = true; 
  };
  ren.guest.summers-jellyfin = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "jellyfin";
     eternorPaths = [ "Videos" ]; withZfs = true; 
  };
  ren.guest.summers-kanidm = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "kanidm";
    withZfs = true; 
  };
  ren.guest.summers-kavita = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "kavita";
     eternorPaths = [ "Books" ]; withZfs = true; 
  };
  ren.guest.summers-koillection = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "koillection";
    withZfs = true; 
  };
  ren.guest.summers-matrix = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "matrix";
    withZfs = true; 
  };
  ren.guest.summers-mealie = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "mealie";
    withZfs = true; 
  };
  ren.guest.summers-monitoring = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "monitoring";
    withZfs = true; 
  };
  ren.guest.summers-nextcloud = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "nextcloud";
    withZfs = true; 
  };
  ren.guest.summers-paperless = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "paperless";
     eternorPaths = [ "Documents" ]; withZfs = true; 
  };
  ren.guest.summers-radicale = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "radicale";
    withZfs = true; 
  };
  ren.guest.summers-storage = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "storage";
     eternorPaths = [ "Books" "Videos" "Music" "Pictures" "Software" "Documents" ]; withZfs = true; 
  };
  ren.guest.summers-transmission = {
    system = ren.system.x86_64-linux;
    on = ren.host.summers;
    guestName = "transmission";
     eternorPaths = [ "Books" "Videos" "Music" "Software" ]; withZfs = true; 
  };
  ren.aspects.summers.nixos =
    {
      variant,
      globals-defs,
      host,
      config,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
    in
    {

      imports = [
        ../../hosts/nixos/x86_64-linux/summers/hardware-configuration.nix
        ../../hosts/nixos/x86_64-linux/summers/disk-config.nix

        inputs.nixos-hardware.nixosModules.common-cpu-intel

      ]
      ++ lib.optionals (!variant.minimal) [
      ];
      swarselsystems = {
        flakePath = "/root/.dotfiles";
        info = "ASUS Z10PA-D8, 2* Intel Xeon E5-2650 v4, 128GB RAM";
        initrdVLAN = "home";
        isBtrfs = true;
        isCrypted = true;
        isLinux = true;
        isSecureBoot = true;
        isSwap = false;
        localVLANs = [
          "services"
          "home"
        ]; # devices is only provided on interface for bmc
        networkKernelModules = [ "igb" ];
        rootDisk = "/dev/disk/by-id/ata-TS120GMTS420S_J024880123";
        server.restic.targets = {
          SwarselState = {
            # nextcloud stores all data in state dir and has no data that needs backup
            paths = lib.map (guest: "/Vault/guests/${guest}/state") (
              builtins.filter (name: name != "nextcloud") (builtins.attrNames config.guests)
            );
            repository = config.repo.secrets.local.resticRepoState;
          };
          SwarselStorage = {
            paths = [
              "/Vault/Eternor/Pictures"
              "/Vault/Eternor/Documents/paperless"
            ];
            repository = config.repo.secrets.local.resticRepoStorage;
          };
        };
        withMicroVMs = true;
        writeGlobalNetworks = false;
      };
      topology.self.interfaces = {
        bmc = { };
        lan = { };
      };
      boot = {
        blacklistedKernelModules = [
          "snd_virtuoso"
          "snd_oxygen"
        ];
        initrd.kernelModules = [
          "vfio_pci"
          "vfio_iommu_type1"
          "vfio"
        ];
        kernelParams = [
          "intel_iommu=on"
          "iommu=pt"
          "vfio-pci.ids=13f6:8788"
        ];
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot.enable = true;
        };
      };
      hardware.enableRedistributableFirmware = true;

    }
    // lib.optionalAttrs (!variant.minimal) {


      networking.nftables.firewall.zones.untrusted.interfaces = [
        "lan"
        "bmc"
      ];

    };
}
