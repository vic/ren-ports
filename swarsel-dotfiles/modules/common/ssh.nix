{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects = {
    ssh.homeManager =
      {
        globals-defs,
        osConfig ? null,
        config,
        lib,
        ...
      }:
      let
        globals = sw.globalsOf globals-defs;
        confLib = sw.confLibOf { host = null; inherit globals config osConfig; };
      in
      {
        config = {
          swarselsystems.enabledHomeModules = [ "ssh" ];
          programs.ssh = {
            enable = true;
            enableDefaultConfig = false;
            extraConfig = ''
              SetEnv TERM=xterm-256color
              ServerAliveInterval 20
            '';
            includes = [ "~/.ssh/extra/*" ];
            settings = {
              "*" = {
                addKeysToAgent = "no";
                compression = false;
                controlMaster = "no";
                controlPath = "~/.ssh/master-%r@%n:%p";
                controlPersist = "no";
                forwardAgent = false;
                hashKnownHosts = false;
                serverAliveCountMax = 3;
                serverAliveInterval = 0;
                userKnownHostsFile = "~/.ssh/known_hosts";
              };
            }
            // confLib.getConfig.repo.secrets.common.ssh.hosts;
          };
        }
        // lib.optionalAttrs (osConfig == null) {
          sops.secrets = lib.mkIf (!config.swarselsystems.isPublic) {
            builder-key = {
              mode = "0600";
              path = "${config.home.homeDirectory}/.ssh/builder";
            };
          };
        };
      };
    ssh.nixos =
      {
        globals-defs,
        host,
        config,
        lib,
        ...
      }:
      let
        globals = sw.globalsOf globals-defs;
        confLib = sw.confLibOf { inherit host globals config; };
      in
      {
        config = {
          swarselsystems.enabledServerModules = [ "ssh" ];
          users = {
            users = {
              "${config.swarselsystems.mainUser}".openssh.authorizedKeys.keyFiles = lib.mkIf (!config.swarselsystems.isMicroVM) [
                (sw.root "files/public/ssh/yubikey.pub")
                (sw.root "files/public/ssh/magicant.pub")
                # (lib.mkIf config.swarselsystems.isBastionTarget (sw.root "files/public/ssh/jump.pub"))
              ];
              root.openssh.authorizedKeys.keyFiles = [
                (sw.root "files/public/ssh/yubikey.pub")
                (sw.root "files/public/ssh/magicant.pub")
                # (lib.mkIf config.swarselsystems.isBastionTarget (sw.root "files/public/ssh/jump.pub"))
              ];
            };
            persistentIds.sshd = confLib.mkIds 979;
          };
          services.openssh = {
            enable = true;
            hostKeys = [
              {
                path = "/etc/ssh/ssh_host_ed25519_key";
                type = "ed25519";
              }
            ];
            settings = {
              AllowUsers = [
                "root"
                config.swarselsystems.mainUser
              ];
              KbdInteractiveAuthentication = false;
              PasswordAuthentication = false;
              PermitRootLogin = "prohibit-password";
            };
            startWhenNeeded = lib.mkForce false;
          };
          security.sudo.extraConfig = ''
            Defaults    env_keep+=SSH_AUTH_SOCK
          '';
        };
      };
  };
}
