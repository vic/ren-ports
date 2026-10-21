{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.symlink.homeManager =
    {
      ...
    }:
    {
    config = {
      swarselsystems.enabledHomeModules = [ "symlink" ];
      home.file = {
        # on NixOS, Emacs does not find the aspell dicts easily. Write the configuration manually
        ".aspell.conf" = {
          source = sw.root "files/config/.aspell.conf";
          target = ".aspell.conf";
        };
        ".gitmessage" = {
          source = sw.root "files/git/.gitmessage";
          target = ".gitmessage";
        };
      };
      xdg.configFile = {
        "tridactyl/themes/swarsel.css".source = sw.root "files/firefox/tridactyl/themes/swarsel.css";
        "tridactyl/tridactylrc".source = sw.root "files/firefox/tridactyl/tridactylrc";
      };
    };
  };
}
