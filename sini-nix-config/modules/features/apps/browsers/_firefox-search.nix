# Search engine config; called with pkgs.
pkgs: {
  force = true;
  engines = {
    "Nix Packages" = {
      urls = [
        {
          template = "https://search.nixos.org/packages";
          params = [
            {
              name = "type";
              value = "packages";
            }
            {
              name = "channel";
              value = "unstable";
            }
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }
      ];
      icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = [ "@np" ];
    };

    "Nix Options" = {
      urls = [
        {
          template = "https://search.nixos.org/options";
          params = [
            {
              name = "type";
              value = "options";
            }
            {
              name = "channel";
              value = "unstable";
            }
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }
      ];
      icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = [ "@no" ];
    };

    "HomeManager" = {
      urls = [
        { template = "https://home-manager-options.extranix.com/?query={searchTerms}&release=master"; }
      ];
      icon = "https://github.com/mipmip/home-manager-option-search/blob/main/images/favicon.png";
      updateInterval = 24 * 60 * 60 * 1000;
      definedAliases = [ "@hm" ];
    };

    "NixWiki" = {
      urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
      icon = "https://nixos.org/favicon.png";
      updateInterval = 24 * 60 * 60 * 1000;
      definedAliases = [ "@nw" ];
    };
  };
  default = "Brave";
}
