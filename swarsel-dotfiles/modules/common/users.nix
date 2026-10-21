{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.users.nixos =
    {
      variant,
      globals-defs,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
    in
    {
      config = {
        sops.secrets.main-user-hashed-pw = lib.mkIf (!config.swarselsystems.isPublic) {
          neededForUsers = true;
        };

        users = {
          users = {
            "${config.swarselsystems.mainUser}" = {
              autoSubUidGidRange = false;
              description = config.repo.secrets.common.fullName or "User";
              extraGroups = [
                "wheel"
              ]
              ++ lib.optionals (!variant.minimal && !config.swarselsystems.isMicroVM) [
                "networkmanager"
                "input"
                "syncthing"
                "docker"
                "lp"
                "audio"
                "video"
                "vboxusers"
                "builder"
                "libvirtd"
                "scanner"
              ];
              hashedPasswordFile = lib.mkIf (
                !variant.minimal && !config.swarselsystems.isPublic
              ) config.sops.secrets.main-user-hashed-pw.path;
              isNormalUser = true;
              packages = with pkgs; [ ];
              password = lib.mkIf (variant.minimal || config.swarselsystems.isPublic) "setup";
              subGidRanges = [
                {
                  count = 65534;
                  startGid = 100001;
                }
              ];
              subUidRanges = [
                {
                  count = 65534;
                  startUid = 100001;
                }
              ];
              uid = 1000;
            };
            root = {
              inherit (globals.root) hashedPassword;
              # shell = pkgs.zsh;
            };
          };
          mutableUsers = lib.mkIf (!variant.minimal) false;
        };
      };
    };
}
