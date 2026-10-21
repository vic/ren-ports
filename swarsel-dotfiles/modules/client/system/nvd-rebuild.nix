{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.nvd-rebuild.nixos =
    {
      pkgs,
      ...
    }:
    {
    config = {

      environment.systemPackages = [
        pkgs.nvd
      ];

      # system.activationScripts.diff = {
      #   supportsDryActivation = true;
      #   text = ''
      #     ${pkgs.nvd}/bin/nvd --color=always --nix-bin-dir=${pkgs.nix}/bin diff \
      #          /run/current-system "$systemConfig"
      #   '';
      # };
    };
  };
}
