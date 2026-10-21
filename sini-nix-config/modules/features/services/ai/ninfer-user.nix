# ninfer: dedicated system user (see ninfer.nix).
{ ... }:
{
  ren.aspects.svc-ai-ninfer.nixos = {
    users.groups.ninfer = { };
    users.users.ninfer = {
      group = "ninfer";
      isSystemUser = true;
    };
  };
}
