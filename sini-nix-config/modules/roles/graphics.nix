{
  ren.aspects.graphics = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.blender
          pkgs.krita
          pkgs.gimp
          pkgs.inkscape
        ];
      };
  };
}
