{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.bastion.nixos =
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
        swarselsystems.enabledServerModules = [ "bastion" ];
        users = {
          users.jump = {
            autoSubUidGidRange = false;
            createHome = lib.mkForce true;
            group = lib.mkForce "jump";
            isNormalUser = true;
            openssh.authorizedKeys.keyFiles = [
              (sw.root "files/public/ssh/yubikey.pub")
              (sw.root "files/public/ssh/magicant.pub")
              (sw.root "files/public/ssh/builder.pub")
            ];
            useDefaultShell = true;
          };
          groups.jump = { };
          persistentIds.jump = confLib.mkIds 1001;
        };
        services.openssh = {
          enable = true;
          authorizedKeysInHomedir = false;
          extraConfig = ''
            Match User jump
              PermitTTY no
              X11Forwarding no
              PermitTunnel no
              GatewayPorts no
              AllowAgentForwarding no
          '';
          hostKeys = lib.mkIf (!(builtins.elem "ssh" config.swarselsystems.enabledServerModules)) [
            {
              path = "/etc/ssh/ssh_host_ed25519_key";
              type = "ed25519";
            }
          ];
          settings = {
            AllowUsers = [
              "jump"
            ];
            KbdInteractiveAuthentication = false;
            PasswordAuthentication = false;
            PermitRootLogin = lib.mkDefault "no";
          };
          startWhenNeeded = lib.mkForce false;
        };
      }
      // lib.optionalAttrs (!config.swarselsystems.isMicroVM) {

        home-manager.users.jump.config = {
          programs.ssh = {
            enable = true;
            enableDefaultConfig = false;
            settings = {
              "*".forwardAgent = false;
            }
            // config.repo.secrets.local.ssh.hosts;
          };
          home.stateVersion = lib.mkDefault "23.05";
        };
      };
    }

  ;
}
