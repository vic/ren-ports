# mensa-nixos: Adda's homelab server, the tailnet's exit node and the table every service is served from.
{ ren, inputs, ... }:
{
  ren.host.mensa-nixos = {
    system = ren.system.x86_64-linux;
    users = [ ren.user.adda ];
    description = "NixOS homelab server";
    longDescription = ''
      "mensa" is Latin for "table", which is also what a "desktop" literally is: this is the one machine that stays on
      the desk instead of being carried around. It has since grown into the table everything is served from (files,
      documents, feeds, podcasts, notifications, DNS) and into the tailnet's exit node, so the other hosts eat here too.
    '';
    workstation = false;
    swap = {
      # swapfile = { sizeGiB = 32; zswap = true; };
      zram = { };
      swapspace = true;
    };
    vmAutologin = ren.user.adda;
  };

  ren.aspects.mensa-nixos = {
    at = ren.host.mensa-nixos;
    nixos =
      { lib, ... }:
      {
        imports = [
          inputs.omniflake.unified.disko.nixosModules.disko
          ./_disko.nix
          ./_hardware.nix
        ]
        ++ (with inputs.omniflake.unified.nixos-hardware.nixosModules; [
          common-cpu-amd
          common-gpu-amd
          common-pc-ssd
          common-pc
        ]);

        # mensa-nixos is the tailnet's primary exit node and the only host that advertises unconditionally; clients
        # consume it via addax.network.tailscaleExitNodeClient.
        #
        # It is deliberately NOT tagged. A tag transfers ownership of the device from Adda to the tag, which strips its
        # user identity; and caddy-tailscale's tailscale_auth rejects tagged nodes outright ("node %s has tags", see
        # auth.go), so a tagged  mensa-nixos cannot reach any of its own caddy-fronted services (ntfy, paperless,
        # freshrss, nextcloud, pinepods, adguard) over the tailnet. The two properties the tag used to provide are
        # covered without it, both in terraform/tailscale/exit-node.tf:
        #  - exit-node auto-approval: "autoApprovers.exitNode" lists autogroup:owner, which is what Adda actually is
        #    (the Owner role is not part of autogroup:admin).
        #  - a node key that never expires: tailscale_device_key pins key_expiry_disabled, which for user-owned devices
        #    would otherwise reset to 180 days on re-enrolment.
        #
        # Consequently there is no authKeyFile here either: its only purpose was to make the tag declarative
        # (`tailscale set` has no --advertise-tags, and nixpkgs only builds tailscaled-autoconnect.service, the sole
        # consumer of extraUpFlags, when a key is set). Worse, an auth key carries its own tags, so enrolling with the
        # old "tag:exit-node" key re-tagged the device no matter what flags were passed. Enrolment after a reinstall is
        # now a one-time interactive `tailscale up`.
        services.tailscale = {
          # Reasserted on every boot by tailscaled-set.service, which nixpkgs generates from  extraSetFlags alone; no
          # auth key required. Needs no netmap lookup.
          extraSetFlags = [ "--advertise-exit-node" ];
        };

        # The shared default pins boot.loader.timeout = null so workstations wait in the GRUB menu forever. A headless
        # server must come back up unattended after a power cut, so auto-boot the default entry instead; 5s still leaves
        # a window to pick an older generation on an attached console.
        boot.loader.timeout = lib.mkForce 5;

        # Blank the text console after 5 minutes of no VT input, which also drops the connector to DPMS off on the KMS
        # driver. The kernel default is 0 (never). Nothing here runs a compositor at idle, so this saves no host power;
        # it is purely for the attached panel: standby instead of displaying a static login prompt indefinitely. Boot-
        # time only; `setterm --blank` would affect just one tty.
        boot.kernelParams = [ "consoleblank=300" ];
      };
    includes = with ren.aspects; [
      audio-pipewire
      fonts
      hardware-bareMetal
      kernel-xanmod
      filesystems-ntfs
      network-networkManager

      # DE is installed but must not run unattended: this host is a 24/7 server, so it boots to a text console and the
      # desktop is started on demand with `desktop-start`.
      desktop-headlessBoot

      services-caddy
      services-paperless
      # services-grafana
      services-nextcloud
      # services-languagetool
      services-freshrss
      # services-karakeep
      services-pinepods
      services-ntfy-sh
      services-litellm
      services-tsidp

      # DNS resolver for the tailnet; mutually exclusive; all bind :53.
      # services-dns-technitium
      services-dns-adguardhome
      # services-dns-pihole
      # services-dns-blocky
    ];
  };
}
