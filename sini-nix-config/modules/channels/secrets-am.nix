# a-m channels, secrets: each emission is a module ({ age.secrets.<n> = ...; }); the receiver is the emitter scope.
# The `into` key is picked by the receiver's kind, from its bindings only (never from the pool).
{ ren, ... }:
{
  ren.channels.age-secrets = {
    fold = ren.lib.fold.list;
    to = e: e;
    into =
      {
        user ? null,
        cluster ? null,
        mac ? null,
        ...
      }:
      ms:
      if user != null then
        { homeManager.imports = ms; }
      else if cluster != null then
        { k8s-manifests.imports = ms; }
      else if mac != null then
        { darwin.imports = ms; }
      else
        { nixos.imports = ms; };
  };
}
