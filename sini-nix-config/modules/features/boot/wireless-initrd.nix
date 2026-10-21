# Wireless initrd unlock: wpa_supplicant layer over boot-network-initrd
# for remote LUKS/ZFS unlock over WiFi. Interface auto-detected from the facter
# report, so the boot config is a no-op on hosts without a wireless NIC.
# Secrets and activation scripts live in wireless-initrd-secrets.nix.
{ ren, ... }:
{
  ren.aspects.boot-wireless-initrd = {
    includes = with ren.aspects; [ boot-network-initrd ];

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        # Auto-detect the wireless interface (wl*) from the facter report.
        wirelessInterface = lib.findFirst (
          iface:
          iface ? unix_device_name && lib.hasPrefix "wl" iface.unix_device_name && iface ? driver_modules
        ) null config.facter.report.hardware.network_interface;

        hasWireless = wirelessInterface != null;
        interface = if hasWireless then wirelessInterface.unix_device_name else "";
      in
      {
        boot.initrd = lib.mkIf hasWireless {
          # WPA crypto modules (network drivers come from boot-network-initrd).
          #
          # ccm/ctr/cmac are only the crypto *templates*. mac80211 asks the
          # crypto API for the composed algorithm "ccm(aes)", and the cipher it
          # composes over is resolved separately at runtime: no module link
          # records that dependency, so the initrd closure never pulls it in.
          # Without an AES implementation present, allocating ccm(aes) fails and
          # the association dies right after the 4-way handshake with "kernel
          # reports: key addition failed" / "Failed to set PTK to the driver",
          # which looks like a wifi problem but is a missing-cipher problem.
          # "aes" is the generic implementation and is what makes it work at
          # all; aesni_intel is the accelerated path.
          availableKernelModules = [
            "ccm"
            "ctr"
            "cmac"
            "aes"
            "aesni_intel"
          ];

          compressor = "zstd";
          compressorArgs = [ "-12" ];
          extraFirmwarePaths = [ "iwlwifi-so-a0-gf-a0-89.ucode.zst" ];

          systemd = {
            packages = [ pkgs.wpa_supplicant ];
            # The initrd's own systemd (boot.initrd.systemd.package) is already
            # in the bin env; listing pkgs.systemd here duplicated it. It was
            # harmless only while both resolved to a byte-identical derivation;
            # once the channels' systemd patch sets diverged the two distinct
            # store paths collided in buildEnv on bin/udevadm. Don't re-add it.
            initrdBin = [
              pkgs.wpa_supplicant
              pkgs.coreutils
              pkgs.iproute2
            ];

            targets.initrd.wants = [
              "wpa_supplicant@${interface}.service"
              "systemd-resolved.service"
            ];
            services = {
              "wpa_supplicant@" = {
                unitConfig.DefaultDependencies = false;
                after = lib.mkForce [ "sys-subsystem-net-devices-%i.device" ];
                requires = lib.mkForce [ "sys-subsystem-net-devices-%i.device" ];
              };

              systemd-networkd.after = [ "wpa_supplicant@${interface}.service" ];

              sshd = {
                after = lib.mkForce [ "network.target" ];
                wants = lib.mkForce [ ];
                requires = lib.mkForce [ ];
              };

              resolved.enable = true;
            };
          };

          secrets."/etc/wpa_supplicant/wpa_supplicant-${interface}.conf" =
            config.age.secrets.wpa-supplicant-initrd.path;
        };
      };
  };
}
