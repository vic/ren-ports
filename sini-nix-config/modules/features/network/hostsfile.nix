# /etc/hosts + SSH known_hosts (NixOS) and known_hosts (Darwin) from the
# fleet-wide host-addrs channel. Darwin pins only the tailnet name (LAN
# addresses are unreachable while roaming).
{ ren, ... }:
{
  ren.aspects.network-hostsfile = {
    # This host and its microvm guests: a guest resolves under its parent, so the
    # fleet-wide collect never reaches it on its own.
    host-addrs =
      { environment, host, ... }:
      map (h: {
        hostname = h.name;
        domain = "${h.environment.name}.${environment.domain}";
        # Tailnet MagicDNS name: resolves on darwin and NixOS, LAN forms don't off-LAN.
        tsName = "${h.name}.ts.${environment.domain}";
        ipv4 = ren.helpers.ipv4Of h;
        publicKeyFile = h.public_key;
      }) ([ host ] ++ host.guests);

    nixos =
      { host-addrs, config, lib, ... }:
      let
        peers = lib.filter (e: e.hostname != config.networking.hostName) host-addrs;
      in
      {
        networking.hosts = lib.listToAttrs (
          map (
            entry:
            lib.nameValuePair (builtins.head entry.ipv4) [
              entry.hostname
              "${entry.hostname}.${entry.domain}"
            ]
          ) (lib.filter (e: e.ipv4 != [ ]) peers)
        );

        # tsName is pinned unconditionally: it is the only name that works
        # off-LAN (the `.<env>.<domain>` form hits the public edge, which accepts
        # TCP then never speaks SSH). peer-sync runs BatchMode, so an unpinned
        # `.ts.` name is a hard "Host key verification failed".
        services.openssh.knownHosts = lib.listToAttrs (
          map (
            entry:
            lib.nameValuePair entry.hostname {
              hostNames = [
                entry.hostname
                "${entry.hostname}.${entry.domain}"
                entry.tsName
              ]
              ++ entry.ipv4;
              inherit (entry) publicKeyFile;
            }
          ) peers
        );
      };

    darwin =
      { host-addrs, config, lib, ... }:
      {
        # `ssh <host>` connects via the tailnet name (aliased in dev-security ssh);
        # pin each peer key under it so the connection verifies, not TOFU-prompts.
        programs.ssh.knownHosts = lib.listToAttrs (
          map (
            entry:
            lib.nameValuePair entry.hostname {
              hostNames = [
                entry.hostname
                entry.tsName
                "${entry.hostname}.${entry.domain}"
              ]
              ++ entry.ipv4;
              inherit (entry) publicKeyFile;
            }
          ) (lib.filter (e: e.hostname != config.networking.hostName) host-addrs)
        );
      };
  };
}
