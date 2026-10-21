# Domains: one per zone or sub-zone, below the fleet; aspects select them with `at`.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt maybe;
  t = lib.types;
  req = type: lib.mkOption { inherit type; };
in
{
  ren.kinds.domain = {
    zone = maybe t.str; # parent zone FQDN, null for an apex zone
    dns = {
      provider = opt t.str "cloudflare";
      account = maybe t.str;
    };
    tls = {
      issuer = opt t.str "dns01";
      resourceName = maybe t.str;
    };
    web = opt (t.enum [ "apex" "landing" "none" ]) "none";
    # Same arguments sini's mail.protonmail / pages.github aspects took.
    mail = maybe (t.submodule {
      options.protonmail = maybe (t.submodule {
        options = {
          verification = req t.str;
          dkimDomain = req t.str;
          dmarc = req t.str;
        };
      });
    });
    pages = maybe (t.submodule {
      options.github = maybe (t.submodule {
        options = {
          user = req t.str;
          verification = maybe t.str;
        };
      });
    });
    records = opt (t.listOf t.raw) [ ];
  };
}
