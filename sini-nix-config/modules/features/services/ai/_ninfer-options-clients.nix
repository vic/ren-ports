# ninfer settings options, client admission (see ninfer.nix).
{ lib, types, ... }:
{
  clients = lib.mkOption {
    default = null;
    description = ''
      Who may reach the port besides every host consuming
      ninfer-endpoints (ninfer-clients: its addresses, or its
      environment's network when it has none): the nodes of these k3s
      clusters (pods masquerade to their node address) and these extra
      hosts, by their addresses in the collected k3s-nodes and host-addrs.
      A name that resolves to no address fails the evaluation. null = any
      source.
    '';
    type = lib.types.nullOr (
      lib.types.submodule {
        options = {
          clusters = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "k3s cluster names whose nodes may connect.";
          };
          hosts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Host names that may connect.";
          };
        };
      }
    );
  };
}
