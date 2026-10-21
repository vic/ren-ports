{
  ren.aspects.cad = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.kicad
          pkgs.freecad-wayland
          pkgs.openscad
          pkgs.orca-slicer
        ];
      };
  };
}
