# browsers: librewolf/firefox profiles + mullvad browser flatpak
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.browsers.os = {
    services.flatpak.packages = [
      "net.mullvad.MullvadBrowser"
      # "re.sonny.Junction"
      # "io.github.zen_browser.zen"
    ];
  };

  ren.aspects.browsers.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      librewolfPackage = lib.getExe config.programs.librewolf.package;
      librewolfPackageName = addax.getExeName config.programs.librewolf.package;

      # From https://discourse.nixos.org/t/flatten-nested-set-to-name-value-pairs-named-after-the-old-path/59713.
      flatten =
        set:
        let
          recurse =
            path:
            lib.concatMapAttrs (
              name: value:
              if builtins.isAttrs value then
                recurse (path ++ [ name ]) value
              else
                { ${builtins.concatStringsSep "." (path ++ [ name ])} = value; }
            );
        in
        recurse [ ] set;

      search = {
        force = true;
        engines = {
          ecosia = {
            name = "Ecosia Search";
            definedAliases = [
              "@e"
              "@ecosia"
            ];
            urls = [
              {
                template = "https://www.ecosia.org/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            iconMapObj."48" = "https://www.ecosia.org/static/icons/favicon.ico";
          };

          kagi = {
            name = "Kagi Search";
            definedAliases = [
              "@k"
              "@kagi"
            ];
            urls = [
              {
                template = "https://kagi.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            iconMapObj."48" = "https://kagi.com/favicon.ico";
          };

          duckduckgo = {
            name = "DuckDuckGo";
            urls = [ { template = "https://duckduckgo.com/?q={searchTerms}"; } ];
            iconMapObj."16" = "https://duckduckgo.com/favicon.ico";
            definedAliases = [
              "@d"
              "@ddg"
              "@duckduckgo"
            ];
          };

          bing.metaData.hidden = true;
          google.metaData.alias = "@g"; # builtin engines only support specifying one additional alias

          nix-packages = {
            name = "Nix Packages";
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  # {
                  #   name = "from";
                  #   value = "0";
                  # }
                  # {
                  #   name = "size";
                  #   value = "50";
                  # }
                  # {
                  #   name = "sort";
                  #   value = "relevance";
                  # }
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          nixos-wiki = {
            name = "NixOS Wiki";
            urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
            iconMapObj."16" = "https://wiki.nixos.org/favicon.ico";
            definedAliases = [ "@nw" ];
          };
        };

        default = "ecosia";
      };

      settingsGlobal = {
        ui = {
          context_menus.after_mouseup = true;
          key.menuAccessKeyFocuses = false;
        };
        browser = {
          gesture.swipe = {
            left = "";
            right = "";
          };
          urlbar.trimURLs = true; # Trim 'http(s)://' from the URL bar.
          search.defaultenginename = "Ecosia";
          bookmarks.showMobileBookmarks = true;
          tabs.loadBookmarksInTabs = true;
          ctrlTab.sortByRecentlyUsed = true;
          newtabpage.enabled = false;
          startup.homepage = "about:blank";
          toolbars.bookmarks.visibility = "never";
        };
        #dom.security.https_only_mode = true;
        sidebar = {
          verticalTabs = true;
          "verticalTabs.dragToPinPromo".dismissed = true;
          position_start = false;
        };
        print = {
          print_footerleft = "";
          print_footerright = "";
          print_headerleft = "";
          print_headerright = "";
        };
        #privacy.trackingprotection.enabled = true;
      };

      nativeMessagingHosts = with pkgs; [
        tridactyl-native
        kdePackages.plasma-browser-integration
      ];

      languagePacks = [
        "cs"
        "en-GB"
        "en-US"
      ];

      userChrome = ''
        #main-window[tabsintitlebar="true"]:not([extradragspace="true"]) #TabsToolbar > .toolbar-items {
          opacity: 0;
          pointer-events: none;
        }

        #main-window:not([tabsintitlebar="true"]) #TabsToolbar {
            visibility: collapse !important;
        }
      '';

      policies = {
        DontCheckDefaultBrowser = true;
      };
    in
    {
      home.packages = with pkgs; [
        ungoogled-chromium
        tor-browser
      ];

      programs.firefox = {
        enable = true;

        inherit languagePacks nativeMessagingHosts policies;

        profiles = {
          default = {
            id = 0;
            inherit search userChrome;
            settings =
              settingsGlobal
              // {
              }
              |> flatten;
          };
        };
      };

      programs.librewolf = {
        enable = true;

        inherit languagePacks nativeMessagingHosts policies;

        settings =
          settingsGlobal
          // {
          }
          |> flatten;

        profiles = {
          default = {
            id = 0;
            inherit search userChrome;
            settings =
              {
                identity.fxaccounts.enabled = true;
              }
              |> flatten;
            # extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            #   ublock-origin
            # ];
          };

          fun = {
            id = 1;
            inherit userChrome;
            settings =
              settingsGlobal
              // {
              }
              |> flatten;
          };
        };
      };

      xdg.desktopEntries = {
        librewolf-default = {
          name = "LibreWolf (Default)";
          comment = "Web Browser - Default Profile";
          exec = "${librewolfPackage} -P default --class ${librewolfPackageName}-default";
          icon = librewolfPackageName;
          terminal = false;
          categories = [
            "Network"
            "WebBrowser"
          ];
          settings = {
            StartupWMClass = "${librewolfPackageName}-default";
          };
        };

        librewolf-fun = {
          name = "LibreWolf (Fun)";
          comment = "Web Browser - Fun Profile";
          exec = "${librewolfPackage} -P fun --class ${librewolfPackageName}-fun";
          icon = librewolfPackageName;
          terminal = false;
          categories = [
            "Network"
            "WebBrowser"
          ];
          settings = {
            StartupWMClass = "${librewolfPackageName}-fun";
          };
        };
      };

      # xdg.configFile."tridactyl/trydactilrc".text = ''
      # '';
    };
}
