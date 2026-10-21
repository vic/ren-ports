{ ren, ... }:
{
  ren.aspects.nix-builder = {
    includes = with ren.aspects; [ svc-nix-remote-build-server ];

    nix-builders =
      { host, ... }:
      {
        hostname = host.name;
        ip = builtins.head host.ipv4;
        inherit (host) system;
        inherit (host) secretPath;
      };
  };
}
