# peer-sync: installs the local package of the same name (pkgs/by-name/peer-sync).
# Moves a host's git refs into a peer's remote-tracking namespace so in-flight work transfers.
{ ... }:
{
  ren.aspects.dev-ai-tools-peer-sync.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.local.peer-sync ];
    };
}
