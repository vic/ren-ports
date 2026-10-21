{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.git.homeManager =
    {
      variant,
      globals-defs,
      osConfig ? null,
      config,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { host = null; inherit globals config; inherit osConfig; };
      inherit (confLib.getConfig.repo.secrets.common.mail) address1;
      inherit (confLib.getConfig.repo.secrets.common) fullName;
      inherit (config.swarselsystems) homeDir mainUser;

      gitUser = globals.user.name;
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "git" ];
        programs = {
          difftastic.enable = lib.mkIf (!variant.minimal) true;
          git = {
            enable = true;
          }
          // lib.optionalAttrs (!variant.minimal) {
            includes = [
              {
                contents = {
                  commit.template = "~/.gitmessage";
                  github.user = gitUser;
                };
              }
            ];
            lfs.enable = true;
            maintenance.enable = true;
            settings = {
              alias = {
                a = "add";
                b = "branch";
                c = "commit";
                cl = "clone";
                co = "checkout";
                i = "init";
                m = "merge";
                p = "pull";
                pp = "push";
                r = "restore";
                s = "status";
              };
              maintenance.prefetch.enabled = false;
              user = {
                email = lib.mkIf ((osConfig != null) && !config.swarselsystems.isPublic) (
                  lib.mkDefault address1
                );
                name = lib.mkIf ((osConfig != null) && !config.swarselsystems.isPublic) fullName;
              };
            };
            signing = {
              format = "openpgp";
              key = "0x76FD3810215AE097";
              signByDefault = true;
            };
          };
        };
        systemd.user.tmpfiles.rules = [
          "f ${homeDir}/.gitconfig 0644 ${mainUser} users - -"
        ];
      };
    };
}
