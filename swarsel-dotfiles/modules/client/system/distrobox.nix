{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.distrobox.nixos =
    {
      globals-defs,
      host,
      config,
      pkgs,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
    in
    {
    config = {

      users.persistentIds.podman = confLib.mkIds 969;
      environment.systemPackages = with pkgs; [
        distrobox
        boxbuddy
      ];
      virtualisation.podman = {
        enable = true;
        package = pkgs.podman;
        dockerCompat = true;
      };
    };
  };
}
