# clion: JetBrains CLion.
{ ren, ... }:
{
  ren.aspects.editors-clion.homeManager =
    { pkgs, ... }:
    {
      services.flatpak.packages = [
        # "com.jetbrains.CLion"
      ];

      home.packages = with pkgs; [
        jetbrains.clion
      ];
    };
}
