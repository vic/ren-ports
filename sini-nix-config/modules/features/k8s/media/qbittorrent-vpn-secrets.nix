# qBittorrent VPN secrets: WireGuard material issued by ProtonVPN, NO generator by design
# (operator fills via `agenix edit`: age -r master recipient -o .secrets/env/prod/media-vpn/<field>.age);
# rekeyed into sops file `media-vpn` and surfaced as the k8s Secret `media-vpn`.
{ ren, ... }:
{
  # own aspect: one aspect's channel value must agree across files, qbittorrent.nix emits age-secrets too
  ren.aspects.k8s-media-qbittorrent-vpn-age-secrets.age-secrets =
      { environment, ... }:
      {
        age.secrets = {
          media-vpn-private-key = {
            rekeyFile = environment.secretPath + "/media-vpn/private-key.age";
            sopsOutput = {
              file = "media-vpn";
              key = "private-key";
            };
          };
          media-vpn-addresses = {
            rekeyFile = environment.secretPath + "/media-vpn/addresses.age";
            sopsOutput = {
              file = "media-vpn";
              key = "addresses";
            };
          };
          media-vpn-peer-public-key = {
            rekeyFile = environment.secretPath + "/media-vpn/peer-public-key.age";
            sopsOutput = {
              file = "media-vpn";
              key = "peer-public-key";
            };
          };
          media-vpn-endpoint-ip = {
            rekeyFile = environment.secretPath + "/media-vpn/endpoint-ip.age";
            sopsOutput = {
              file = "media-vpn";
              key = "endpoint-ip";
            };
          };
          media-vpn-endpoint-port = {
            rekeyFile = environment.secretPath + "/media-vpn/endpoint-port.age";
            sopsOutput = {
              file = "media-vpn";
              key = "endpoint-port";
            };
          };
        };
      };

  ren.aspects.k8s-media-qbittorrent = {
    includes = [ ren.aspects.k8s-media-qbittorrent-vpn-age-secrets ];
    k8s-manifests =
      { config, ... }:
      {
        applications.qbittorrent.resources.secrets.media-vpn = {
          type = "Opaque";
          stringData = {
            private-key = config.age.secrets.media-vpn-private-key.sopsRef;
            addresses = config.age.secrets.media-vpn-addresses.sopsRef;
            peer-public-key = config.age.secrets.media-vpn-peer-public-key.sopsRef;
            endpoint-ip = config.age.secrets.media-vpn-endpoint-ip.sopsRef;
            endpoint-port = config.age.secrets.media-vpn-endpoint-port.sopsRef;
          };
        };
      };
  };
}
