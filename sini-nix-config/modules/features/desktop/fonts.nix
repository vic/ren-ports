# desktop-style-fonts: fontconfig defaults; pulls nerd + regular font sets
{ ren, ... }:
{
  ren.aspects.desktop-style-fonts = {
    includes = with ren.aspects; [
      desktop-style-fonts-nerd-fonts
      desktop-style-fonts-regular
    ];

    nixos = {
      fonts = {
        enableDefaultPackages = true;
        fontDir.enable = true;

        fontconfig = {
          enable = true;
          useEmbeddedBitmaps = true;
          localConf = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <dir>/usr/local/share/fonts/t</dir>
            </fontconfig>
          '';
          defaultFonts = {
            monospace = [ "Monaspace Neon NF" ];
            sansSerif = [ "Inter" ];
            serif = [ "Source Serif" ];
            emoji = [ "Noto Color Emoji" ];
          };
        };
      };
    };

    homeManager.fonts.fontconfig.enable = true;
  };
}
