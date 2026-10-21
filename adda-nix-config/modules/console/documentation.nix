# documentation: man pages and NixOS docs
{ ren, ... }:
{
  ren.aspects.documentation = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          man-pages
        ];
      };
    os = {
      documentation = {
        dev.enable = true;
        man.cache.enable = true;
        nixos.includeAllModules = true;
        nixos.options.warningsAreErrors = false;
      };
    };
  };
}
