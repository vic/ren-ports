{ ren, ... }:
{
  ren.aspects.gamedev = {
    includes = with ren.aspects; [
      game-engines
      pixel-art
      graphics
      daw
      chiptune
    ];
  };
}
