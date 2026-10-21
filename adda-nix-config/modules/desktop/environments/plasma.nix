# desktop-environments-plasma: KDE Plasma session, plasma-manager
{ ren, inputs, ... }:
{
  ren.aspects.desktop-environments-plasma.os =
    { pkgs, ... }:
    let
      patchedXkeyboardConfig = pkgs.xkeyboard_config.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          substituteInPlace $out/share/X11/xkb/symbols/cz \
            --replace-fail \
              '    key <AD03>	{[         e,           E,             e,   EuroSign ]};' \
              '    key <AD03>	{[         e,           E,        ecaron,     eacute ]};' \
            --replace-fail \
              '    key <BKSL>	{[ backslash,        bar, dead_diaeresis, apostrophe ]};' \
              '    key <BKSL>	{[ backslash,        bar, dead_diaeresis, apostrophe ]};
          key <AC01>	{[         a,          A,        aacute,     Aacute ]};
          key <AB03>	{[         c,          C,        ccaron,     Ccaron ]};
          key <AC03>	{[         d,          D,        dcaron,     Dcaron ]};
          key <AD08>	{[         i,          I,        iacute,     Iacute ]};
          key <AB06>	{[         n,          N,        ncaron,     Ncaron ]};
          key <AD09>	{[         o,          O,        oacute,     Oacute ]};
          key <AD04>	{[         r,          R,        rcaron,     Rcaron ]};
          key <AC02>	{[         s,          S,        scaron,     Scaron ]};
          key <AD05>	{[         t,          T,        tcaron,     Tcaron ]};
          key <AD07>	{[         u,          U,         uring,     uacute ]};
          key <AD06>	{[         y,          Y,        yacute,     Yacute ]};
          key <AB01>	{[         z,          Z,        zcaron,     Zcaron ]};'
        '';
      });
    in
    {
      services.xserver.xkb.dir = "${patchedXkeyboardConfig}/etc/X11/xkb";

      # `services.xserver.xkb.dir` only wires up Xorg and exports SYSTEMD_XKB_DIRECTORY (consumed by
      #   systemd-localed/vconsole), which KWin's Wayland session ignores.
      # KWin resolves keymaps via libxkbcommon directly, which only honors XKB_CONFIG_ROOT; without it, libxkbcommon
      #  falls back to whatever (unpatched) xkeyboard-config it was compiled against, silently dropping the patch above.
      environment.variables.XKB_CONFIG_ROOT = "/etc/X11/xkb";

      services.displayManager.plasma-login-manager = {
        enable = true;
      };
      services.desktopManager.plasma6.enable = true;
      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        discover
      ];
      # security.pam.services.login.kwallet = {
      #   enable = true;
      #   # forceRun = true;
      # };
      security.pam.services.sddm.kwallet = {
        enable = true;
        # forceRun = true;
      };
      # security.pam.services.kde.kwallet = {
      #   enable = true;
      #   forceRun = true;
      # };
      # services.gnome.gnome-keyring.enable = false;

      # environment.systemPackages = with pkgs; [
      #   kdePackages.kwallet-pam
      #   kdePackages.kwallet
      #   kdePackages.kwalletmanager
      # ];
    };

  ren.aspects.desktop-environments-plasma.homeManager =
    { config, pkgs, ... }:
    {
      imports = [
        inputs.omniflake.unified.plasma-manager.homeModules.plasma-manager
      ];
      home.packages = with pkgs; [
        kdePackages.knewstuff
        kdePackages.flatpak-kcm
        kdePackages.appstream-qt
        kdePackages.kate
        kdePackages.yakuake
        kdePackages.kget
        kdePackages.kalarm
        kdePackages.kasts
      ];

      programs.plasma = {
        enable = true;
        overrideConfig = false;

        workspace = {
          clickItemTo = "select"; # If you liked the click-to-open default from plasma 5.
          lookAndFeel = "org.kde.breezedark.desktop";
          # cursor = {
          #   theme = "Breeze";
          #   # size = 32;
          # };
          # iconTheme = "Breeze";
          # wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Next/contents/images_dark/5120x2880.png";
          wallpaper = "${config.xdg.userDirs.pictures}/wallpaper.png";
        };

        fonts = {
          general = {
            family = "JetBrains Mono";
            pointSize = 12;
          };
        };

        panels = [
          {
            location = "top";
            height = 26;
            widgets = [
              # We can configure the widgets by adding the name and config
              # attributes. For example to add the the kickoff widget and set the
              # icon to "nix-snowflake-white" use the below configuration. This will
              # add the "icon" key to the "General" group for the widget in
              # ~/.config/plasma-org.kde.plasma.desktop-appletsrc.
              # {
              #   name = "org.kde.plasma.kickoff";
              #   config = {
              #     General = {
              #       icon = "nix-snowflake-white";
              #       alphaSort = true;
              #     };
              #   };
              # }
              # Or you can configure the widgets by adding the widget-specific options for it.
              # See modules/widgets for supported widgets and options for these widgets.
              # For example:
              {
                kickoff = {
                  sortAlphabetically = true;
                  icon = "nix-snowflake-white";
                };
              }

              "org.kde.plasma.pager"

              # {
              #   applicationTitleBar = {
              #     behavior = {
              #       activeTaskSource = "activeTask";
              #     };
              #     layout = {
              #       elements = [ "windowTitle" ];
              #       horizontalAlignment = "left";
              #       showDisabledElements = "deactivated";
              #       verticalAlignment = "center";
              #     };
              #     overrideForMaximized.enable = false;
              #     titleReplacements = [
              #       {
              #         type = "regexp";
              #         originalTitle = "^Brave Web Browser$";
              #         newTitle = "Brave";
              #       }
              #       {
              #         type = "regexp";
              #         originalTitle = ''\\bDolphin\\b'';
              #         newTitle = "File manager";
              #       }
              #     ];
              #     windowTitle = {
              #       font = {
              #         bold = false;
              #         fit = "fixedSize";
              #         size = 12;
              #       };
              #       hideEmptyTitle = true;
              #       margins = {
              #         bottom = 0;
              #         left = 10;
              #         right = 5;
              #         top = 0;
              #       };
              #       source = "appName";
              #     };
              #   };
              # }

              # "org.kde.plasma.appmenu"

              # "org.kde.plasma.panelspacer"

              # Adding configuration to the widgets can also for example be used to
              # pin apps to the task-manager, which this example illustrates by
              # pinning dolphin and konsole to the task-manager by default with widget-specific options.
              {
                iconTasks = {
                  launchers = [
                    #   "applications:org.kde.dolphin.desktop"
                    #   "applications:org.kde.konsole.desktop"
                  ];
                };
              }
              # Or you can do it manually, for example:
              # {
              #   name = "org.kde.plasma.icontasks";
              #   config = {
              #     General = {
              #       launchers = [
              #         "applications:org.kde.dolphin.desktop"
              #         "applications:org.kde.konsole.desktop"
              #       ];
              #     };
              #   };
              # }
              # # If no configuration is needed, specifying only the name of the
              # widget will add them with the default configuration.
              # "org.kde.plasma.marginsseparator"
              # If you need configuration for your widget, instead of specifying the
              # the keys and values directly using the config attribute as shown
              # above, plasma-manager also provides some higher-level interfaces for
              # configuring the widgets. See modules/widgets for supported widgets
              # and options for these widgets. The widgets below shows two examples
              # of usage, one where we add a digital clock, setting 12h time and
              # first day of the week to Sunday and another adding a systray with
              # some modifications in which entries to show.

              "org.kde.plasma.panelspacer"

              {
                digitalClock = {
                  calendar.firstDayOfWeek = "monday";
                  time.format = "24h";
                };
              }

              "org.kde.plasma.panelspacer"

              {
                plasmusicToolbar = {
                  panelIcon = {
                    albumCover = {
                      useAsIcon = false;
                      radius = 8;
                    };
                    icon = "view-media-track";
                  };
                  # preferredSource = "spotify";
                  # showPlaybackControls = true;
                  songText = {
                    displayInSeparateLines = true;
                    maximumWidth = 640;
                    scrolling = {
                      behavior = "alwaysScroll";
                      speed = 3;
                    };
                  };
                };
              }

              {
                systemTray.items = {
                  # Explicitly shown.
                  shown = [
                    "org.kde.plasma.battery"
                    "org.kde.plasma.bluetooth"
                    "org.kde.plasma.networkmanagement"
                    "org.kde.plasma.volume"
                  ];
                  # Explicitly hide.
                  hidden = [ ];
                };
              }
            ];
            hiding = "normalpanel";
          }
        ];

        kwin = {
          virtualDesktops = {
            rows = 2;
            number = 20;
          };

          nightLight = {
            enable = true;
            mode = "constant";
            temperature.night = 4500;
          };

          titlebarButtons = {
            # left = [];
            right = [
              "help"
              "minimize"
              "maximize"
              "close"
            ];
          };

          # shakeCursor.enable = true;
          # snapHelper.enable = true;
          borderlessMaximizedWindows = true;
        };

        hotkeys = {
          commands = {
            "launch-terminal" = {
              name = "Launch terminal";
              command = "alacritty";
              key = "Meta+Enter";
            };
          };
        };

        # window-rules = [
        #   {
        #     description = "Dolphin";
        #     match = {
        #       window-class = {
        #         value = "dolphin";
        #         type = "substring";
        #       };
        #       window-types = [ "normal" ];
        #     };
        #     apply = {
        #       noborder = {
        #         value = true;
        #         apply = "force";
        #       };
        #       # `apply` defaults to "apply-initially"
        #       maximizehoriz = true;
        #       maximizevert = true;
        #     };
        #   }
        # ];

        # powerdevil = {
        #   powerButtonAction = "lockScreen";
        #   autoSuspend = {
        #     action = "shutDown";
        #     idleTimeout = 1000;
        #   };
        #   turnOffDisplay = {
        #     idleTimeout = 1000;
        #     idleTimeoutWhenLocked = "immediately";
        #   };
        # };

        configFile = {
          baloofilerc."Basic Settings"."Indexing-Enabled" = false;
          #   "baloofilerc"."General"."dbVersion" = 2;
          #   "baloofilerc"."General"."exclude filters" = "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.tfstate*,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,.terraform,.venv,venv,core-dumps,lost+found";
          #   "baloofilerc"."General"."exclude filters version" = 9;
          #   "kactivitymanagerdrc"."activities"."5c0d009a-515c-46e9-9f3e-c93af4471bc1" = "Default";
          #   "kactivitymanagerdrc"."main"."currentActivity" = "5c0d009a-515c-46e9-9f3e-c93af4471bc1";
          #   "kcminputrc"."Keyboard"."NumLock" = 0;
          #   "kded5rc"."Module-browserintegrationreminder"."autoload" = false;
          #   "kded5rc"."Module-device_automounter"."autoload" = false;
          #   "kdeglobals"."DirSelect Dialog"."DirSelectDialog Size" = "960,540";
          #   "kdeglobals"."KFileDialog Settings"."Allow Expansion" = false;
          #   "kdeglobals"."KFileDialog Settings"."Automatically select filename extension" = true;
          #   "kdeglobals"."KFileDialog Settings"."Breadcrumb Navigation" = false;
          #   "kdeglobals"."KFileDialog Settings"."Decoration position" = 2;
          #   "kdeglobals"."KFileDialog Settings"."LocationCombo Completionmode" = 5;
          #   "kdeglobals"."KFileDialog Settings"."PathCombo Completionmode" = 5;
          #   "kdeglobals"."KFileDialog Settings"."Show Bookmarks" = false;
          #   "kdeglobals"."KFileDialog Settings"."Show Full Path" = false;
          #   "kdeglobals"."KFileDialog Settings"."Show Inline Previews" = true;
          #   "kdeglobals"."KFileDialog Settings"."Show Preview" = false;
          #   "kdeglobals"."KFileDialog Settings"."Show Speedbar" = true;
          #   "kdeglobals"."KFileDialog Settings"."Show hidden files" = false;
          #   "kdeglobals"."KFileDialog Settings"."Sort by" = "Name";
          #   "kdeglobals"."KFileDialog Settings"."Sort directories first" = true;
          #   "kdeglobals"."KFileDialog Settings"."Sort hidden files last" = false;
          #   "kdeglobals"."KFileDialog Settings"."Sort reversed" = false;
          #   "kdeglobals"."KFileDialog Settings"."Speedbar Width" = 140;
          #   "kdeglobals"."KFileDialog Settings"."View Style" = "DetailTree";
          #   "kdeglobals"."WM"."activeBackground" = "49,54,59";
          #   "kdeglobals"."WM"."activeBlend" = "252,252,252";
          #   "kdeglobals"."WM"."activeForeground" = "252,252,252";
          #   "kdeglobals"."WM"."inactiveBackground" = "42,46,50";
          #   "kdeglobals"."WM"."inactiveBlend" = "161,169,177";
          #   "kdeglobals"."WM"."inactiveForeground" = "161,169,177";
          #   "kwalletrc"."Wallet"."First Use" = false;
          kwinrc = {
            NightColor = {
              Active = true;
              Mode = "Constant";
              NightTemperature = 4500;
            };
            Plugins = {
              desktopchangeosdEnabled = false;
              diminactiveEnabled = true;
              hidecursorEnabled = true;
              sheetEnabled = true;
              snaphelperEnabled = true;
              trackmouseEnabled = true;
              virtualdesktopsonlyonprimaryEnabled = true;
            };
            Wayland = {
              "InputMethod[$e]" = "/run/current-system/sw/share/applications/org.kde.plasma.keyboard.desktop";
              VirtualKeyboardMode = 1;
            };
            Windows = {
              BorderlessMaximizedWindows = true;
              PerOutputVirtualDesktops = true;
            };

            # #     "Effect-overview"."BorderActivate" = 9;
            # #     "Tiling"."padding" = 4;
            # #     "Tiling/841710f1-c61f-5c8c-9aac-94d9704542c7"."tiles" = "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
            # #     "Tiling/84533bf8-c04b-53f9-a3cb-9b1adf05af8d"."tiles" = "{\"layoutDirection\":\"horizontal\",\"tiles\":[{\"width\":0.25},{\"width\":0.5},{\"width\":0.25}]}";
            Xwayland.Scale = 1;
          };

          # kxkbrc.Layout = {
          #   DisplayNames = "CZ,US,US_CZ";
          #   LayoutList = "cz,us,bqn";
          #   VariantList = "coder,,cz_sk_de";
          #   Options = "caps:swapescape,grp:shifts_toggle,terminate:ctrl_alt_bksp";
          #   ResetOldOptions = true;
          #   SwitchMode = "Window";
          #   Use = true;
          # };
          # kxkbrc.Layout = {
          #   DisplayNames = "US_CZ";
          #   LayoutList = "bqn";
          #   VariantList = "cz_sk_de";
          #   Options = "caps:swapescape,grp:shifts_toggle,terminate:ctrl_alt_bksp";
          #   ResetOldOptions = true;
          #   SwitchMode = "Window";
          #   Use = true;
          # };
          kxkbrc.Layout = {
            DisplayNames = "CZ";
            LayoutList = "cz";
            VariantList = "coder";
            Options = "grp:shifts_toggle,terminate:ctrl_alt_bksp";
            ResetOldOptions = true;
            SwitchMode = "Window";
            Use = true;
          };

          plasmaparc.General = {
            AudioFeedback = false;
            GlobalMuteSources = true;
            RaiseMaximumVolume = true;
          };

          #   "plasma-localerc"."Formats"."LANG" = "en_GB.UTF-8";
          #   "plasma-localerc"."Formats"."LC_MEASUREMENT" = "cs_CZ.UTF-8";
          #   "plasma-localerc"."Formats"."LC_MONETARY" = "cs_CZ.UTF-8";
          #   "plasma-localerc"."Formats"."LC_TELEPHONE" = "cs_CZ.UTF-8";
          #   "plasmanotifyrc"."Applications/firefox"."Seen" = true;
        };

        shortcuts = {
          ksmserver = {
            "Lock Session" = [
              "Screensaver"
              "Ctrl+Alt+L"
              "Lock Session"
            ]; # Add Meta key, too?
            #     "Halt Without Confirmation" = "none,,Shut Down Without Confirmation";
            #     "Log Out Without Confirmation" = "none,,Log Out Without Confirmation";
            #     "Log Out" = "Ctrl+Alt+Del";
            #     "LogOut" = "none,,Log Out";
            #     "Reboot" = "none,,Reboot";
            #     "Reboot Without Confirmation" = "none,,Reboot Without Confirmation";
            #     "Shut Down" = "none,,Shut Down";
          };
          #   "ActivityManager"."switch-to-activity-5c0d009a-515c-46e9-9f3e-c93af4471bc1" = [ ];
          #   "KDE Keyboard Layout Switcher"."Switch keyboard layout to Czech (QWERTY)" = [ ];
          #   "KDE Keyboard Layout Switcher"."Switch keyboard layout to Czech, Slovak and German (US)" = "Ctrl+Alt+Shift+C,none,Switch keyboard layout to Czech\\, Slovak and German (US)";
          #   "KDE Keyboard Layout Switcher"."Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
          #   "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Alt+K";
          #   "kaccess"."Toggle Screen Reader On and Off" = "Meta+Alt+S";
          #   "kcm_touchpad"."Disable Touchpad" = "Touchpad Off";
          #   "kcm_touchpad"."Enable Touchpad" = "Touchpad On";
          #   "kcm_touchpad"."Toggle Touchpad" = ["Touchpad Toggle" "Meta+Ctrl+Zenkaku Hankaku,Touchpad Toggle" "Meta+Ctrl+Zenkaku Hankaku"];
          #   "kmix"."decrease_microphone_volume" = "Microphone Volume Down";
          "kmix"."decrease_volume" = [
            "Meta+Shift+Down"
            "Volume Down"
          ];
          #   "kmix"."decrease_volume_small" = "Shift+Volume Down";
          #   "kmix"."increase_microphone_volume" = "Microphone Volume Up";
          "kmix"."increase_volume" = [
            "Meta+Shift+Up"
            "Volume Up"
          ];
          #   "kmix"."increase_volume_small" = "Shift+Volume Up";
          #   "kmix"."mic_mute" = ["Microphone Mute" "Meta+Volume Mute,Microphone Mute" "Meta+Volume Mute,Mute Microphone"];
          #   "kmix"."mute" = "Volume Mute";
          #   "kwin"."Activate Window Demanding Attention" = "Meta+Ctrl+A";
          #   "kwin"."Cycle Overview" = [ ];
          #   "kwin"."Cycle Overview Opposite" = [ ];
          #   "kwin"."Decrease Opacity" = "none,,Decrease Opacity of Active Window by 5%";
          #   "kwin"."Edit Tiles" = "Meta+T";
          #   "kwin"."Expose" = "Ctrl+F9";
          #   "kwin"."ExposeAll" = ["Ctrl+F10" "Launch (C),Ctrl+F10" "Launch (C),Toggle Present Windows (All desktops)"];
          #   "kwin"."ExposeClass" = "Ctrl+F7";
          #   "kwin"."ExposeClassCurrentDesktop" = [ ];
          #   "kwin"."Grid View" = "Meta+G";
          #   "kwin"."Increase Opacity" = "none,,Increase Opacity of Active Window by 5%";
          #   "kwin"."Kill Window" = "Meta+Ctrl+Esc";
          #   "kwin"."Move Tablet to Next Output" = [ ];
          #   "kwin"."MoveMouseToCenter" = "Meta+F6";
          #   "kwin"."MoveMouseToFocus" = "Meta+F5";
          #   "kwin"."MoveZoomDown" = [ ];
          #   "kwin"."MoveZoomLeft" = [ ];
          #   "kwin"."MoveZoomRight" = [ ];
          #   "kwin"."MoveZoomUp" = [ ];
          #   "kwin"."Overview" = "Meta+W";
          #   "kwin"."Setup Window Shortcut" = "none,,Setup Window Shortcut";
          #   "kwin"."Show Desktop" = "Meta+D";
          #   "kwin"."Switch One Desktop Down" = "Meta+Ctrl+Down";
          #   "kwin"."Switch One Desktop Up" = "Meta+Ctrl+Up";
          #   "kwin"."Switch One Desktop to the Left" = "Meta+Ctrl+Left";
          #   "kwin"."Switch One Desktop to the Right" = "Meta+Ctrl+Right";
          #   "kwin"."Switch Window Down" = "Meta+Alt+Down";
          #   "kwin"."Switch Window Left" = "Meta+Alt+Left";
          #   "kwin"."Switch Window Right" = "Meta+Alt+Right";
          #   "kwin"."Switch Window Up" = "Meta+Alt+Up";
          #   "kwin"."Switch to Desktop 1" = "Ctrl+F1";
          #   "kwin"."Switch to Desktop 10" = "none,,Switch to Desktop 10";
          #   "kwin"."Switch to Desktop 11" = "none,,Switch to Desktop 11";
          #   "kwin"."Switch to Desktop 12" = "none,,Switch to Desktop 12";
          #   "kwin"."Switch to Desktop 13" = "none,,Switch to Desktop 13";
          #   "kwin"."Switch to Desktop 14" = "none,,Switch to Desktop 14";
          #   "kwin"."Switch to Desktop 15" = "none,,Switch to Desktop 15";
          #   "kwin"."Switch to Desktop 16" = "none,,Switch to Desktop 16";
          #   "kwin"."Switch to Desktop 17" = "none,,Switch to Desktop 17";
          #   "kwin"."Switch to Desktop 18" = "none,,Switch to Desktop 18";
          #   "kwin"."Switch to Desktop 19" = "none,,Switch to Desktop 19";
          #   "kwin"."Switch to Desktop 2" = "Ctrl+F2";
          #   "kwin"."Switch to Desktop 20" = "none,,Switch to Desktop 20";
          #   "kwin"."Switch to Desktop 3" = "Ctrl+F3";
          #   "kwin"."Switch to Desktop 4" = "Ctrl+F4";
          #   "kwin"."Switch to Desktop 5" = "none,,Switch to Desktop 5";
          #   "kwin"."Switch to Desktop 6" = "none,,Switch to Desktop 6";
          #   "kwin"."Switch to Desktop 7" = "none,,Switch to Desktop 7";
          #   "kwin"."Switch to Desktop 8" = "none,,Switch to Desktop 8";
          #   "kwin"."Switch to Desktop 9" = "none,,Switch to Desktop 9";
          #   "kwin"."Switch to Next Desktop" = "none,,Switch to Next Desktop";
          #   "kwin"."Switch to Next Screen" = "none,,Switch to Next Screen";
          #   "kwin"."Switch to Previous Desktop" = "none,,Switch to Previous Desktop";
          #   "kwin"."Switch to Previous Screen" = "none,,Switch to Previous Screen";
          #   "kwin"."Switch to Screen 0" = "none,,Switch to Screen 0";
          #   "kwin"."Switch to Screen 1" = "none,,Switch to Screen 1";
          #   "kwin"."Switch to Screen 2" = "none,,Switch to Screen 2";
          #   "kwin"."Switch to Screen 3" = "none,,Switch to Screen 3";
          #   "kwin"."Switch to Screen 4" = "none,,Switch to Screen 4";
          #   "kwin"."Switch to Screen 5" = "none,,Switch to Screen 5";
          #   "kwin"."Switch to Screen 6" = "none,,Switch to Screen 6";
          #   "kwin"."Switch to Screen 7" = "none,,Switch to Screen 7";
          #   "kwin"."Switch to Screen Above" = "none,,Switch to Screen Above";
          #   "kwin"."Switch to Screen Below" = "none,,Switch to Screen Below";
          #   "kwin"."Switch to Screen to the Left" = "none,,Switch to Screen to the Left";
          #   "kwin"."Switch to Screen to the Right" = "none,,Switch to Screen to the Right";
          #   "kwin"."Toggle Night Color" = [ ];
          #   "kwin"."Toggle Window Raise/Lower" = "none,,Toggle Window Raise/Lower";
          "kwin"."Walk Through Windows" = [
            "Meta+K"
            "Alt+Tab,Alt+Tab,Walk Through Windows"
          ];
          #   "kwin"."Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
          #   "kwin"."Walk Through Windows Alternative" = "none,,Walk Through Windows Alternative";
          "kwin"."Walk Through Windows Alternative (Reverse)" =
            "Meta+J,,Walk Through Windows Alternative (Reverse)";
          #   "kwin"."Walk Through Windows of Current Application" = "Alt+`";
          #   "kwin"."Walk Through Windows of Current Application (Reverse)" = "Alt+~";
          #   "kwin"."Walk Through Windows of Current Application Alternative" = "none,,Walk Through Windows of Current Application Alternative";
          #   "kwin"."Walk Through Windows of Current Application Alternative (Reverse)" = "none,,Walk Through Windows of Current Application Alternative (Reverse)";
          #   "kwin"."Window Above Other Windows" = "none,,Keep Window Above Others";
          #   "kwin"."Window Below Other Windows" = "none,,Keep Window Below Others";
          "kwin"."Window Close" = [
            "Meta+Q"
            "Alt+F4,Alt+F4,Close Window"
          ];
          #   "kwin"."Window Fullscreen" = "none,,Make Window Fullscreen";
          #   "kwin"."Window Grow Horizontal" = "none,,Expand Window Horizontally";
          #   "kwin"."Window Grow Vertical" = "none,,Expand Window Vertically";
          #   "kwin"."Window Lower" = "none,,Lower Window";
          "kwin"."Window Maximize" = "Meta+Up";
          #   "kwin"."Window Maximize Horizontal" = "none,,Maximise Window Horizontally";
          #   "kwin"."Window Maximize Vertical" = "none,,Maximise Window Vertically";
          "kwin"."Window Minimize" = "Meta+Down";
          #   "kwin"."Window Move" = "none,,Move Window";
          #   "kwin"."Window Move Center" = "none,,Move Window to the Centre";
          #   "kwin"."Window No Border" = "none,,Toggle Window Titlebar and Frame";
          #   "kwin"."Window On All Desktops" = "none,,Keep Window on All Desktops";
          #   "kwin"."Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
          #   "kwin"."Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
          #   "kwin"."Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
          #   "kwin"."Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
          #   "kwin"."Window One Screen Down" = "none,,Move Window One Screen Down";
          #   "kwin"."Window One Screen Up" = "none,,Move Window One Screen Up";
          #   "kwin"."Window One Screen to the Left" = "none,,Move Window One Screen to the Left";
          #   "kwin"."Window One Screen to the Right" = "none,,Move Window One Screen to the Right";
          #   "kwin"."Window Operations Menu" = "Alt+F3";
          #   "kwin"."Window Pack Down" = "none,,Move Window Down";
          #   "kwin"."Window Pack Left" = "none,,Move Window Left";
          #   "kwin"."Window Pack Right" = "none,,Move Window Right";
          #   "kwin"."Window Pack Up" = "none,,Move Window Up";
          #   "kwin"."Window Quick Tile Bottom" = "Meta+Down";
          #   "kwin"."Window Quick Tile Bottom Left" = "none,,Quick Tile Window to the Bottom Left";
          #   "kwin"."Window Quick Tile Bottom Right" = "none,,Quick Tile Window to the Bottom Right";
          #   "kwin"."Window Quick Tile Left" = "Meta+Left";
          #   "kwin"."Window Quick Tile Right" = "Meta+Right";
          #   "kwin"."Window Quick Tile Top" = "none,Meta+Up,Quick Tile Window to the Top";
          #   "kwin"."Window Quick Tile Top Left" = "none,,Quick Tile Window to the Top Left";
          #   "kwin"."Window Quick Tile Top Right" = "none,,Quick Tile Window to the Top Right";
          #   "kwin"."Window Raise" = "none,,Raise Window";
          #   "kwin"."Window Resize" = "none,,Resize Window";
          #   "kwin"."Window Shade" = "none,,Shade Window";
          #   "kwin"."Window Shrink Horizontal" = "none,,Shrink Window Horizontally";
          #   "kwin"."Window Shrink Vertical" = "none,,Shrink Window Vertically";
          #   "kwin"."Window to Desktop 1" = "none,,Window to Desktop 1";
          #   "kwin"."Window to Desktop 10" = "none,,Window to Desktop 10";
          #   "kwin"."Window to Desktop 11" = "none,,Window to Desktop 11";
          #   "kwin"."Window to Desktop 12" = "none,,Window to Desktop 12";
          #   "kwin"."Window to Desktop 13" = "none,,Window to Desktop 13";
          #   "kwin"."Window to Desktop 14" = "none,,Window to Desktop 14";
          #   "kwin"."Window to Desktop 15" = "none,,Window to Desktop 15";
          #   "kwin"."Window to Desktop 16" = "none,,Window to Desktop 16";
          #   "kwin"."Window to Desktop 17" = "none,,Window to Desktop 17";
          #   "kwin"."Window to Desktop 18" = "none,,Window to Desktop 18";
          #   "kwin"."Window to Desktop 19" = "none,,Window to Desktop 19";
          #   "kwin"."Window to Desktop 2" = "none,,Window to Desktop 2";
          #   "kwin"."Window to Desktop 20" = "none,,Window to Desktop 20";
          #   "kwin"."Window to Desktop 3" = "none,,Window to Desktop 3";
          #   "kwin"."Window to Desktop 4" = "none,,Window to Desktop 4";
          #   "kwin"."Window to Desktop 5" = "none,,Window to Desktop 5";
          #   "kwin"."Window to Desktop 6" = "none,,Window to Desktop 6";
          #   "kwin"."Window to Desktop 7" = "none,,Window to Desktop 7";
          #   "kwin"."Window to Desktop 8" = "none,,Window to Desktop 8";
          #   "kwin"."Window to Desktop 9" = "none,,Window to Desktop 9";
          #   "kwin"."Window to Next Desktop" = "none,,Window to Next Desktop";
          #   "kwin"."Window to Next Screen" = "Meta+Shift+Right";
          #   "kwin"."Window to Previous Desktop" = "none,,Window to Previous Desktop";
          #   "kwin"."Window to Previous Screen" = "Meta+Shift+Left";
          #   "kwin"."Window to Screen 0" = "none,,Move Window to Screen 0";
          #   "kwin"."Window to Screen 1" = "none,,Move Window to Screen 1";
          #   "kwin"."Window to Screen 2" = "none,,Move Window to Screen 2";
          #   "kwin"."Window to Screen 3" = "none,,Move Window to Screen 3";
          #   "kwin"."Window to Screen 4" = "none,,Move Window to Screen 4";
          #   "kwin"."Window to Screen 5" = "none,,Move Window to Screen 5";
          #   "kwin"."Window to Screen 6" = "none,,Move Window to Screen 6";
          #   "kwin"."Window to Screen 7" = "none,,Move Window to Screen 7";
          #   "kwin"."view_actual_size" = "Meta+0";
          #   "kwin"."view_zoom_in" = ["Meta++" "Meta+=,Meta++" "Meta+=,Zoom In"];
          #   "kwin"."view_zoom_out" = "Meta+-";
          #   "mediacontrol"."mediavolumedown" = "none,,Media volume down";
          #   "mediacontrol"."mediavolumeup" = "none,,Media volume up";
          #   "mediacontrol"."nextmedia" = "Media Next";
          #   "mediacontrol"."pausemedia" = "Media Pause";
          #   "mediacontrol"."playmedia" = "none,,Play media playback";
          #   "mediacontrol"."playpausemedia" = "Media Play";
          #   "mediacontrol"."previousmedia" = "Media Previous";
          #   "mediacontrol"."stopmedia" = "Media Stop";
          #   "org_kde_powerdevil"."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
          #   "org_kde_powerdevil"."Decrease Screen Brightness" = "Monitor Brightness Down";
          #   "org_kde_powerdevil"."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
          #   "org_kde_powerdevil"."Hibernate" = "Hibernate";
          #   "org_kde_powerdevil"."Increase Keyboard Brightness" = "Keyboard Brightness Up";
          #   "org_kde_powerdevil"."Increase Screen Brightness" = "Monitor Brightness Up";
          #   "org_kde_powerdevil"."Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
          #   "org_kde_powerdevil"."PowerDown" = "Power Down";
          #   "org_kde_powerdevil"."PowerOff" = "Power Off";
          #   "org_kde_powerdevil"."Sleep" = "Sleep";
          #   "org_kde_powerdevil"."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
          #   "org_kde_powerdevil"."Turn Off Screen" = [ ];
          #   "org_kde_powerdevil"."powerProfile" = ["Battery" "Meta+B,Battery" "Meta+B,Switch Power Profile"];
          #   "plasmashell"."activate application launcher" = ["Meta" "Alt+F1,Meta" "Alt+F1,Activate Application Launcher"];
          #   "plasmashell"."activate task manager entry 1" = "Meta+1";
          #   "plasmashell"."activate task manager entry 10" = "none,Meta+0,Activate Task Manager Entry 10";
          #   "plasmashell"."activate task manager entry 2" = "Meta+2";
          #   "plasmashell"."activate task manager entry 3" = "Meta+3";
          #   "plasmashell"."activate task manager entry 4" = "Meta+4";
          #   "plasmashell"."activate task manager entry 5" = "Meta+5";
          #   "plasmashell"."activate task manager entry 6" = "Meta+6";
          #   "plasmashell"."activate task manager entry 7" = "Meta+7";
          #   "plasmashell"."activate task manager entry 8" = "Meta+8";
          #   "plasmashell"."activate task manager entry 9" = "Meta+9";
          #   "plasmashell"."clear-history" = "none,,Clear Clipboard History";
          #   "plasmashell"."clipboard_action" = "Meta+Ctrl+X";
          #   "plasmashell"."cycle-panels" = "Meta+Alt+P";
          #   "plasmashell"."cycleNextAction" = "none,,Next History Item";
          #   "plasmashell"."cyclePrevAction" = "none,,Previous History Item";
          #   "plasmashell"."manage activities" = "none,Meta+Q,Show Activity Switcher";
          #   "plasmashell"."next activity" = "Meta+A,none,Walk through activities";
          #   "plasmashell"."previous activity" = "Meta+Shift+A,none,Walk through activities (Reverse)";
          #   "plasmashell"."repeat_action" = "none,Meta+Ctrl+R,Manually Invoke Action on Current Clipboard";
          #   "plasmashell"."show dashboard" = "Ctrl+F12";
          #   "plasmashell"."show-barcode" = "none,,Show Barcode…";
          #   "plasmashell"."show-on-mouse-pos" = "Meta+V";
          #   "plasmashell"."stop current activity" = "Meta+S";
          #   "plasmashell"."switch to next activity" = "none,,Switch to Next Activity";
          #   "plasmashell"."switch to previous activity" = "none,,Switch to Previous Activity";
          #   "plasmashell"."toggle do not disturb" = "none,,Toggle do not disturb";
        };
      };
    };
}
