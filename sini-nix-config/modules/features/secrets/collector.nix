# Collector: den deduped `age-secrets` emissions by secret name (shallow mergeAttrsList,
# last wins) and set age.secrets only when non-empty. In Ren that merge is the
# `age-secrets` channel (fold.list, modules/channels/secrets-am.nix) `into`;
# this aspect carries no config, kept so includes of secrets-collector resolve.
{ ... }:
{
  ren.aspects.secrets-collector = { };
}
