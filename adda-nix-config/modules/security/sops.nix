# security: sops-nix with the host ssh key as age identity
{ ren, inputs, ... }:
let
  addax = ren.helpers;
in
{

  ren.aspects.security-sops.os =
    { pkgs, ... }:
    {
      imports = [
        inputs.omniflake.unified.sops-nix.nixosModules.sops
      ];

      sops = {
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = addax.secretsPath "secrets.yaml";
      };

      environment.systemPackages = with pkgs; [
        age
        sops
        ssh-to-age
        ssh-to-pgp
      ];
    };
}
