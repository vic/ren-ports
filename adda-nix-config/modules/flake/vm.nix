# vm: `nix run .#vm-<host>` runs a host in a VM, to test config edits without a reboot.
# It is very useful to have a VM: You can edit your config and launch the VM to test stuff instead of having to reboot each time.
# (the tty autologin the old file included is the host field `ttyAutologin`)
{ ren, inputs, ... }:
{
  ren.aspects.vm-apps = {
    at = ren.system.x86_64-linux;
    apps =
      { system, ... }:
      let
        inherit (inputs.nixpkgs) lib;
        pkgs = system.legacyPackages;
        hosts = builtins.attrNames inputs.self.nixosConfigurations;
        vms = map (
          hostName:
          let
            vmName = "vm-${hostName}";
            host = inputs.self.nixosConfigurations.${hostName}.config;
          in
          {
            name = vmName;
            value = {
              type = "app";
              meta.description = "Run adda@${vmName} in a VM for testing before applying changes.";
              program = lib.getExe (
                pkgs.writeShellApplication {
                  name = vmName;
                  text = ''
                    ${host.system.build.vm}/bin/run-${hostName}-vm "$@"
                  '';
                }
              );
            };
          }
        ) hosts;
      in
      builtins.listToAttrs vms;
  };
}
