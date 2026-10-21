# syncthing: user syncthing + tray, no default folder
{ ren, ... }:
{
  ren.aspects.syncthing = {
    homeManager =
      { pkgs, ... }:
      {
        services.syncthing.enable = true;
        home.packages = [ pkgs.syncthingtray ];
      };

    os = {
      # Syncthing creates ~/Sync on a first start that finds no configuration, which then syncs nothing and has to be
      # removed by hand on every new machine.
      systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";
    };
  };
}
