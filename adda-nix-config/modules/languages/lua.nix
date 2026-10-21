# lua: editor wiring for Lua.
{ ren, ... }:
{
  ren.aspects.languages-lua.zed-extensions = { ... }: [ "lua" ];

  ren.aspects.languages-lua.helixLanguages = {
    language = [
      {
        name = "lua";
        scope = "source.lua";
        injection-regex = "lua";
        file-types = [ "lua" ];
        roots = [ ];
        # comment-token = "--";
        indent = {
          tab-width = 4;
          unit = " ";
        };
      }
    ];
  };
}
