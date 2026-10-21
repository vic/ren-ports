# Deterministic UID/GID registry (consistent across hosts for NFS and service accounts).
{ ... }:
{
  ren.aspects.users-deterministic-uids.nixos =
    let
      uidGid = id: {
        uid = id;
        gid = id;
      };
    in
    {
      users.deterministicIds = {
        systemd-oom = uidGid 999;
        systemd-coredump = uidGid 998;
        sshd = uidGid 997;
        nscd = uidGid 996;
        polkituser = uidGid 995;
        microvm = uidGid 994;
        podman = uidGid 993;
        avahi = uidGid 992;
        colord = uidGid 991;
        geoclue = uidGid 990;
        gnome-remote-desktop = uidGid 989;
        rtkit = uidGid 988;
        nm-iodine = uidGid 987;
        openrazer = uidGid 986;
        resolvconf = uidGid 985;
        fwupd-refresh = uidGid 984;
        adbusers = uidGid 983;
        msr = uidGid 982;
        gamemode = uidGid 981;
        greeter = uidGid 980;
        uinput = uidGid 979;
        frr = uidGid 978;
        frrvty = uidGid 977;
        acme = uidGid 976;
        nginx = uidGid 975;
        kanidm = uidGid 974;
        node-exporter = uidGid 973;
        grafana = uidGid 972;
        loki = uidGid 971;
        promtail = uidGid 970;
        vault = uidGid 969;
        wireshark = uidGid 968;
        i2c = uidGid 967;
        tss = uidGid 966;
        alloy = uidGid 965;
        docker = uidGid 964;
        tang = uidGid 963;
        ollama = uidGid 962;
        ninfer = uidGid 945;
        open-webui = uidGid 961;
        gnome-initial-setup = uidGid 960;
        wpa_supplicant = uidGid 959;
        oauth2-proxy = uidGid 958;
        headscale = uidGid 957;
        nix-remote-build = uidGid 956;
        haproxy = uidGid 955;
        pcscd = uidGid 954;
        atticd = uidGid 953;
        git = uidGid 952;
        jellyfin = uidGid 1027;
        process-exporter = uidGid 948;
        docker-registry = uidGid 947;
        opksshuser = uidGid 946;
        genie-public = uidGid 944;
        genie-trusted = uidGid 943;
        matrix-xmsg = uidGid 942;

        # uid deliberately shared with jellyfin (NFS media ownership parity
        # across hosts — NAS files owned 1027:65536 from the legacy stack;
        # jellyfin/uplink and media/axon-01 never coexist on one host).
        # gid 65536 = Synology users group.
        media = {
          uid = 1027;
          gid = 65536;
        };

        system-access = {
          gid = 951;
        };
        workstation-access = {
          gid = 950;
        };
        server-access = {
          gid = 949;
        };
      };
    };
}
