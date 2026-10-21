# setting key host -> nearest non-null settings field: host first, else its environment
# (den scope-engine settings.nix query; Q1 rec: nearest host>env only, no delegation imports).
{ ... }:
{
  ren.helpers.setting =
    key: host: if (host.${key} or null) != null then host.${key} else host.environment.${key} or null;
}
