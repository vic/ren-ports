# Collector: den merged persistHome/cacheHome pools into home.persistence here.
# In Ren that merge lives in the `persistHome` / `cacheHome` channel `into`,
# so this aspect carries no config; kept so `impermanence` includes resolve.
{ ... }:
{
  ren.aspects.impermanence-persist-home-collector = { };
}
