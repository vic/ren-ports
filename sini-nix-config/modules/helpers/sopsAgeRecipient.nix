# sopsAgeRecipient cluster -> age public key read from secretPath/cluster-sops-age-key.pub, or null.
# Path concatenation (not interpolation): interpolating secretPath would copy the whole secret dir to the store.
{ ... }:
{
  ren.helpers.sopsAgeRecipient =
    cluster:
    if
      cluster.secretPath != null && builtins.pathExists (cluster.secretPath + "/cluster-sops-age-key.pub")
    then
      builtins.readFile (cluster.secretPath + "/cluster-sops-age-key.pub")
    else
      null;
}
