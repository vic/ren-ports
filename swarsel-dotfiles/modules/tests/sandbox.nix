# old tests/sandbox.nix: vacanthouse builds with nixpkgs-sandbox, as a host and as a VM test (packages.sandbox-test)
{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.sandbox.flake-inputs.nixpkgs-sandbox.url = "github:tebriel/nixpkgs/homebox/0.26.2";
  ren.aspects.sandbox.at = ren.kinds.fleet;

  ren.classes.nixos-sandbox = {
    at = sw.sandboxed;
    into =
      { host, ... }:
      ms:
      let
        arch = host.system.name;
        overlays = map (n: sw.overlays.${n}) [
          "default"
          "stables"
          "modifications"
        ];
        sandboxPkgs = import host.nixpkgs {
          inherit overlays;
          config.allowUnfree = true;
          system = arch;
        };
        nodeModule = {
          swarselsystems.mainUser = "swarsel";
          networking.hostName = host.name;
          nixpkgs = {
            inherit overlays;
            config.allowUnfree = true;
            hostPlatform = arch;
          };
          node = {
            inherit arch;
            configDir = inputs.self + "/hosts/utility/${host.name}";
            lockFromBootstrapping = true;
            inherit (host) name;
            secretsDir = inputs.self + "/hosts/utility/${host.name}/secrets";
            type = "nixos";
          };
        };
      in
      {
        nixosConfigurations.${host.name} = host.nixpkgs.lib.nixosSystem {
          specialArgs.lib = sandboxPkgs.lib;
          modules = ms ++ [ nodeModule ];
        };
        packages.sandbox-test = sandboxPkgs.testers.runNixOSTest {
          name = "sandbox-${host.name}";
          node = {
            pkgsReadOnly = false;
            specialArgs.lib = sandboxPkgs.lib;
          };
          testScript = ''
            vacanthouse.start()
            vacanthouse.wait_for_unit("multi-user.target")
            vacanthouse.wait_for_unit("kanidm.service")
            vacanthouse.wait_until_succeeds("curl -sSf https://kanidm.swarsel.internal/status", timeout=600)
            vacanthouse.succeed("curl -sSf https://kanidm.swarsel.internal/oauth2/openid/homebox/.well-known/openid-configuration")
            vacanthouse.wait_until_succeeds("curl -sSf http://127.0.0.1:3004/ready", timeout=600)
            vacanthouse.succeed("curl -sSf -o /dev/null https://oauth.swarsel.internal/oauth2/sign_in")
            vacanthouse.wait_until_succeeds("curl -sSf https://homebox.swarsel.internal/api/v1/status", timeout=600)
          '';
          nodes.${host.name} = {
            imports = ms ++ [ nodeModule ];
            virtualisation = {
              cores = 2;
              memorySize = 4096;
            };
          };
        };
      };
  };
}
