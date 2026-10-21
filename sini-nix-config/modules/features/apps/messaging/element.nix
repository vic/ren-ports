{ ... }:
{
  ren.aspects.app-messaging-element = {
    homeLinux =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.element-desktop ];
      };

    # darwin: TODO homebrew.casks = [ "element" ]; an empty darwin key lands nowhere (no mac has this role)

    persistHome.directories = [
      ".config/Element"
    ];
  };
}
