# Copies SSH authorized_keys from all wheel-group users to root.
{ ... }:
{
  ren.aspects.users-root-user.nixos =
    { config, lib, ... }:
    {
      users.users.root.openssh.authorizedKeys.keys = lib.concatMap (u: u.openssh.authorizedKeys.keys or [ ]) (
        lib.attrValues (lib.filterAttrs (_name: u: builtins.elem "wheel" (u.extraGroups or [ ])) config.users.users)
      );
    };
}
