# The apex is GitHub Pages (sini/gen docs); matrix.gen.wtf is tuwunel.
{ ... }:
{
  ren.domain."gen.wtf" = {
    dns = { provider = "cloudflare"; account = "json64"; };
    tls.issuer = "global";
    pages.github = {
      user = "sini";
      verification = "976e8aa7ced3167338668254c4f312";
    };
  };
}
