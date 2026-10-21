{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager =
    {
      lib,
      ...
    }:
    {
    config.programs.emacs.init.usePackage.dockerfile-mode = {
      enable = true;
      mode = lib.mkForce [ ''"Dockerfile"'' ];
    };
  };
}
