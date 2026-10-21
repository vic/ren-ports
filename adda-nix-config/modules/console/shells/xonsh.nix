# xonsh: xonsh shell config
{ ren, ... }:
{
  ren.aspects.shells-xonsh.homeManager = {
    programs.xonsh = {
      enable = true;
      config = { };
    };
  };
}
