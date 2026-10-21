# Collector: den merged the persist/cache pools into environment.persistence here.
# In Ren that merge lives in the `persist` / `cache` channel `into` (modules/channels/storage-*.nix),
# so this aspect carries no config; kept so `impermanence` includes resolve.
{ ... }:
{
  ren.aspects.impermanence-persist-collector = { };
}
