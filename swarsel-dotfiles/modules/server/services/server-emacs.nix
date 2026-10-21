{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects = {
    server-emacs.homeManager =
      {
        lib,
        ...
      }:
      {
        config = {
          swarselsystems.enabledHomeModules = [ "server-dotfiles" ];
          home.file."init.el" = lib.mkForce {
            source = sw.root "files/emacs/server.el";
            target = ".emacs.d/init.el";
          };
        };
      };
    server-emacs.nixos =
      {
        globals-defs,
        host,
        config,
        ...
      }:
      let
        globals = sw.globalsOf globals-defs;
        confLib = sw.confLibOf { inherit host globals config; };
        inherit
          (confLib.gen {
            name = "emacs";
            port = 9812;
          })
          serviceName
          servicePort
          ;
      in
      {
        config = {
          swarselsystems.enabledServerModules = [ "emacs" ];
          services.${serviceName} = {
            enable = true;
            install = true;
            startWithGraphical = false;
          };
          networking.firewall.allowedTCPPorts = [ servicePort ];
        };
      };
  };
}
