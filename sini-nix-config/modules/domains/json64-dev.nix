# Zone json64.dev.
{ ... }:
{
  ren.domain."json64.dev" = {
    dns = { provider = "cloudflare"; account = "json64"; };
    tls.issuer = "json64-dev";
    # Apex serves /.well-known/matrix/* (Matrix delegation for server_name json64.dev).
    web = "apex";
    mail.protonmail = {
      verification = "af5115ee2fefd384e38c3271eaf24788fc7e3b3c";
      dkimDomain = "d6mzv4vscxbsx7a4d3tpxp73nx2ue5kali46oa7h5xdcq37ngo4oq.domains.proton.ch";
      dmarc = "p=quarantine";
    };
    records = [
      # Grey CNAMEs to the apex; take precedence over derived A records.
      { name = "hs"; type = "CNAME"; content = "json64.dev"; }
      { name = "jellyfin"; type = "CNAME"; content = "json64.dev"; }
      # Shared public IP for ssh and some tailscale users (grey-cloud).
      { name = "vpn"; type = "A"; }
      # Private SMTP relay LB, public so LAN clients verify its cert by name.
      { name = "smtp"; type = "A"; content = "10.11.0.30"; }
      # Monitoring ingest LB.
      { name = "ingest"; type = "A"; content = "10.11.0.31"; }
    ];
  };
}
