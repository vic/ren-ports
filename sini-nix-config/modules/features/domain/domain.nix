# Domain aspect: emits dns/tls/web/mail channel entries from the ren.domain instance data.
# den's parametric dns.cloudflare/dns.records/tls.dns01/web.*/pages.github/mail.protonmail
# aspects (domain.nix) are replaced by ren.kinds.domain fields (layout Q8).
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
  # relative record name -> FQDN ("@" is the domain itself)
  fqdn = domain: name: if name == "@" then domain.name else "${name}.${domain.name}";
  qualify = domain: r: r // { name = fqdn domain r.name; };
  a = name: { inherit name; type = "A"; proxied = true; };
  quote = s: "\"${s}\"";

  # GitHub Pages at the apex (sini pages.github).
  githubPages =
    { user, verification }:
    map (n: { name = "@"; type = "A"; content = "185.199.${toString n}.153"; }) (lib.range 108 111)
    ++ map (n: { name = "@"; type = "AAAA"; content = "2606:50c0:800${toString n}::153"; }) (lib.range 0 3)
    ++ [ { name = "www"; type = "CNAME"; content = "${user}.github.io"; } ]
    ++ lib.optional (verification != null) {
      name = "_github-pages-challenge-${user}";
      type = "TXT";
      content = verification;
    };

  # Proton Mail (sini mail.protonmail).
  protonmail =
    { verification, dkimDomain, dmarc }:
    [
      { name = "@"; type = "MX"; content = "mail.protonmail.ch"; priority = 10; }
      { name = "@"; type = "MX"; content = "mailsec.protonmail.ch"; priority = 20; }
      { name = "@"; type = "TXT"; content = quote "v=spf1 include:_spf.protonmail.ch ~all"; }
      { name = "@"; type = "TXT"; content = quote "protonmail-verification=${verification}"; }
      { name = "_dmarc"; type = "TXT"; content = quote "v=DMARC1; ${dmarc}"; }
    ]
    ++ map (k: { name = "${k}._domainkey"; type = "CNAME"; content = "${k}.domainkey.${dkimDomain}"; }) [
      "protonmail"
      "protonmail2"
      "protonmail3"
    ];
in
{
  ren.aspects.domain = {
    at = ren.kinds.domain;

    # A domain without a zone parent is its own Cloudflare zone.
    dns-zones =
      { domain, ... }:
      lib.optional (domain.zone == null && domain.dns.account != null) {
        zone = domain.name;
        inherit (domain.dns) account;
      };

    dns-records =
      { domain, ... }:
      map (qualify domain) (
        domain.records
        ++ lib.optionals (domain.web != "none") [ (a "@") (a "www") ]
        ++ lib.optionals (domain.pages != null && domain.pages.github != null) (githubPages domain.pages.github)
        ++ lib.optionals (domain.mail != null && domain.mail.protonmail != null) (protonmail domain.mail.protonmail)
      );

    certificate-domains =
      { domain, ... }:
      {
        domain = domain.name;
        issuer = domain.tls.issuer;
        inherit (domain.tls) resourceName;
      };

    apex-domains =
      { domain, ... }: lib.optional (domain.web != "none") { domain = domain.name; };

    site-domains =
      { domain, ... }: lib.optional (domain.web == "landing") { domain = domain.name; };
  };
}
