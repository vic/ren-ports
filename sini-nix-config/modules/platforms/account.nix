# account class: users.users.<login> content from a user aspect, written into its host's nixos or mac's darwin.
{ ren, ... }:
let
  inherit (ren.lib) and within;
  asAccount =
    cls: user: ms:
    {
      ${cls} =
        # pkgs must be named so flatten can pass it to account content
        { pkgs, ... }@a:
        {
          users.users.${user.name} = ren.lib.flatten a ms;
        };
    };
in
{
  ren.classes.account = [
    {
      at = and [
        ren.kinds.user
        (within ren.kinds.host)
      ];
      into = { user, ... }: ms: asAccount "nixos" user ms;
    }
    {
      at = and [
        ren.kinds.user
        (within ren.kinds.mac)
      ];
      into = { user, ... }: ms: asAccount "darwin" user ms;
    }
  ];
}
