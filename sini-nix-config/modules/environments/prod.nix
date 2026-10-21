# Prod environment instance (core). Services: prod-services.nix; unifi: prod-unifi.nix.
{ ren, ... }:
{
  ren.environment.prod = {
    secretPath = ../../.secrets/env/prod;
    wirelessSecretsFile = ../../.secrets/env/prod/wpa_supplicant_psks.age;
    id = 1;
    domain = "json64.dev";
    system-access-groups = [ ren.group.system-access ];

    certificates.issuers = {
      "json64-dev".ageKeyFile = ../../.secrets/env/prod/cloudflare-api-key.age;
      "global".ageKeyFile = ../../.secrets/env/prod/cloudflare-api-key.age;
    };

    # Public DNS: infra/dns/README.md.
    dns.publicIPv4 = "157.131.140.225";

    networks.default = {
        cidr = "10.10.0.0/16";
        ipv6_cidr = "fe80::/64";
        description = "Default network for infrastructure hosts";
        gatewayIp = "10.10.0.1";
        gatewayAsn = 65999;
        gatewayIpV6 = "fe80::962a:6fff:fef2:cf4d";
        # Validating DNS-over-TLS resolvers from two operators, in resolved's
        # "address#tls-name" form (the name authenticates the TLS certificate).
        # No DNS64 resolvers: they synthesise AAAA records that route IPv4-only
        # destinations through a third party's NAT64 gateway.
        dnsServers = [
          "1.1.1.1#cloudflare-dns.com"
          "2606:4700:4700::1111#cloudflare-dns.com"
          "1.0.0.1#cloudflare-dns.com"
          "2606:4700:4700::1001#cloudflare-dns.com"
          "9.9.9.9#dns.quad9.net"
          "2620:fe::fe#dns.quad9.net"
        ];
        wireless = {
          ssid = "The Arcade";
          pskRef = "ext:psk_arcade";
        };
    };

    email = {
      domain = "json64.dev";
      adminEmail = "jason@json64.dev";
    };

    acme = {
      server = "https://acme-v02.api.letsencrypt.org/directory";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
    };

    # Hosts push metrics and logs to the axon cluster's ingest endpoint.
    cluster = ren.cluster.axon;

    timezone = "America/Los_Angeles";

    location = {
      country = "US";
      region = "us-west";
    };

    tags = {
      environment = "prod";
      owner = "json64";
    };
  };
}
