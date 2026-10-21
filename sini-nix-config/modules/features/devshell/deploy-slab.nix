# devshell: remote-deploy slab (nix-on-droid) over SSH via Termux sshd.
{ ... }:
{
  ren.aspects.devshell-deploy-slab.devshell =
    { pkgs, ... }:
    let
      deploy-slab = pkgs.writeShellApplication {
        name = "deploy-slab";
        runtimeInputs = with pkgs; [
          nix
          openssh
        ];
        # Client-side $drv expansion into the remote command is the point:
        # the built activationPackage path must reach the tablet verbatim.
        excludeShellChecks = [ "SC2029" ];
        text = ''
          target="''${1:-slab}"
          echo "==> Building slab activation package..."
          drv=$(nix build --no-link --print-out-paths ".#nixOnDroidConfigurations.slab.activationPackage")
          echo "==> Copying closure to $target..."
          nix-copy-closure --to "ssh://$target" "$drv"
          echo "==> Activating on $target..."
          ssh "$target" "$drv/activate"
        '';
      };
    in
    {
      packages = [ deploy-slab ];
      commands = [
        {
          package = deploy-slab;
          help = "Remote-deploy the slab nix-on-droid config over SSH (Termux sshd)";
        }
      ];
    };
}
