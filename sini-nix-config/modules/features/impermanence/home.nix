# Home Manager persistence for the impermanence aspect.
{ ... }:
{
  ren.aspects.impermanence.homeManager = {
    home.persistence = {
      "/persist" = {
        directories = [
          "Desktop"
          "Documents"
          "Music"
          "Pictures"
          "Public"
          "Templates"
          "Videos"
          {
            directory = ".ssh";
            mode = "0700";
          }
          {
            directory = ".local/share/keyrings";
            mode = "0700";
          }
        ];
      };

      "/cache" = {
        directories = [
          "Downloads"
          ".local/share/direnv"
          ".local/share/nix"
          ".cache"
        ];
      };
    };
  };
}
