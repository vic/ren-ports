# NixOS: the nixos class (one system per host), `os` (OS config a user brings to its host) and `account` (users.users.<login>).
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  inHost = and [
    ren.kinds.user
    (within ren.kinds.host)
  ];
in
{
  ren.classes.nixos = {
    at = ren.kinds.host;
    into = { host, ... }: ms: {
      nixosConfigurations.${host.name} = inputs.nixpkgs.lib.nixosSystem {
        system = host.system.name;
        modules = ms;
      };
    };
  };

  # den routed a user aspect's `nixos` key to the host; here a user aspect writes `os`
  ren.classes.os = {
    at = inHost;
    into = _: ms: { nixos.imports = ms; };
  };

  # users.users is config-only: content becomes one plain value (account content sees the OS module args)
  ren.classes.account = {
    at = inHost;
    into = { user, ... }: ms: {
      nixos =
        # deadnix: skip -- pkgs must be named so flatten can pass it to account content
        { pkgs, ... }@a:
        {
          users.users.${user.name} = ren.lib.flatten a ms;
        };
    };
  };
}
