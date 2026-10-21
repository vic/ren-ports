{ ren, ... }:
{
  ren.host.bitstream = {
    system = ren.system.x86_64-linux;
    channel = ren.channel.nixos-unstable;
    environment = ren.environment.dev;
    system-owner = ren.user.sini;
    system-access-groups = [ ren.group.server-access ];

    networking = {
      bonds.bond0 = {
        interfaces = [
          "eno1"
          "enp2s0"
        ];
        mode = "balance-xor";
        transmitHashPolicy = "layer3+4";
      };
      interfaces.bond0 = {
        ipv4 = [ "10.9.1.1/16" ];
        ipv6 = [ "2001:5a8:608c:4a00::1/64" ];
      };
    };

    disk-zfs-disk-single.device_id = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_1TB_S467NF0K501016P";
    impermanence = {
      wipeRootOnBoot = true;
      wipeHomeOnBoot = false;
    };

    dev-mux-herdr-pair.session = "default";
    dev-mux-herdr-pair.pairs.sini = [ "vic" ];

    # sini's and vic's xmsg nodes here. Their links (to each other and to sini@cortex)
    # and the genie-guard pod's leaf are derived (policies/xmsg.nix).
    dev-ai-mcp-xmsg.federation.nodes = {
      sini = { };
      vic.port = 7789;
    };

    # @genie support bot: #support:json64.dev (testing), #denful:matrix.org and a private room.
    svc-matrix-xmsg = {
      rooms = [
        "!dj6ESTc_Wy5FaLnR-Sj1o_WOqnDeUZWoloV8HuijXs8"
        "!mafjNSATIwbTXcmNzX:matrix.org"
        "!qqfdClEfuMzZNEjvGO:matrix.org" # private room (invite)
        "!NbOtAeWMLV6MjYH3QtXolO8MuGXp6dBfnB0uO8nSpJI" # #genie-dev: tier 1's vetting room (invite)
      ];
      # #genie-dev goes to genie-agent's Tier 1, whose guard-in screens every request;
      # the other rooms stay on genie-support, screened by the bot.
      roomRoutes."!NbOtAeWMLV6MjYH3QtXolO8MuGXp6dBfnB0uO8nSpJI" = {
        expertRef = "genie";
        screenMentions = false;
      };
      extraTrustedMxids = [
        "@theutz:matrix.org"
        "@drupol:matrix.org"
        "@vborja:matrix.org"
        "@sini:matrix.org"
        "@fmway:gitter.im"
      ];
    };
  };

  ren.aspects.bitstream = {
    at = ren.host.bitstream;
    includes = with ren.aspects; [
      default
      server
      dev
      nix-builder

      disk-zfs-disk-single
      boot-network-initrd
      hardware-cpu-amd
      hardware-gpu-amd

      dev-mux-herdr-pair
      svc-matrix-xmsg
      svc-ai-genie-expert
      svc-ai-genie-xmsg
      svc-ai-genie-tier1
    ];
    nixos.facter.reportPath = ../../../hosts/bitstream/facter.json;
  };

  ren.aspects.bitstream-sini = {
    at = ren.lib.and [
      ren.user.sini
      (ren.lib.within ren.host.bitstream)
    ];
    includes = with ren.aspects; [ svc-ai-genie-bank-review ];
  };

  ren.aspects.bitstream-vic = {
    at = ren.lib.and [
      ren.user.vic
      (ren.lib.within ren.host.bitstream)
    ];
    includes = with ren.aspects; [ dev ];
  };
}
