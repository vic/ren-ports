# desktop: user desktop home config + system graphical session
{ ren, ... }:
{
  ren.aspects.desktop.homeManager =
    {
      config,
      pkgs,
      ...
    }:
    {
      # A tray icon and a Qt VPN client. Usable only by desktop workstations, not on headless servers.
      services.tailscale-systray.enable = true;

      home = {
        packages = with pkgs; [
          proton-vpn-cli
          proton-vpn # Flatpak: "com.protonvpn.www"

          appimage-run

          rssguard

          junction

          # inputs'.nixpkgs-local.legacyPackages.atuin-desktop
          atuin-desktop
          # stable.atuin-desktop

          libportal-qt6

          onlyoffice-desktopeditors
          # stirling-pdf-desktop

          # thunderbird
          gparted

          heynote

          discord

          qbittorrent
          transmission_4-qt

          signal-desktop

          boxbuddy

          localsend

          # megasync

          cameractrls

          # wl-clipboard-rs
        ];
      };

      programs.libreoffice = {
        enable = true;
        # settings = {};
      };

      services.wl-clip-persist = {
        enable = false;

      };

      # Nicely reload system units when changing configs
      #systemd.user.startServices = lib.mkIf isLinux "sd-switch";

      home.preferXdgDirectories = true;
      xdg = {
        enable = true;

        mime.enable = true;
        mimeApps = {
          enable = true;
          defaultApplications = {
            "application/pdf" = "org.kde.okular.desktop";

            "text/html" = "librewolf.desktop";
            "x-scheme-handler/http" = "librewolf.desktop";
            "x-scheme-handler/https" = "librewolf.desktop";
            "x-scheme-handler/about" = "librewolf.desktop";
            "x-scheme-handler/unknown" = "librewolf.desktop";
            "x-scheme-handler/heroic" = "com.heroicgameslauncher.hgl.desktop";
            "x-scheme-handler/anytype" = "io.anytype.anytype.desktop";
            "x-scheme-handler/freetube" = "io.freetubeapp.FreeTube.desktop";
            "x-scheme-handler/sgnl" = "signal.desktop";
            "x-scheme-handler/signalcaptcha" = "signal.desktop";
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
              "onlyoffice-desktopeditors.desktop";

            "image/*" = "gwenview.desktop";

            "text/xml" = "helix.desktop";
          };
          associations.added = {
            "x-scheme-handler/heroic" = "com.heroicgameslauncher.hgl.desktop;heroic.desktop";
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
              "onlyoffice-desktopeditors.desktop";
            "x-scheme-handler/anytype" = "io.anytype.anytype.desktop;anytype.desktop";
            "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
              "onlyoffice-desktopeditors.desktop";
            "x-scheme-handler/freetube" = "io.freetubeapp.FreeTube.desktop";
            "x-scheme-handler/sgnl" = "signal.desktop";
            "x-scheme-handler/signalcaptcha" = "signal.desktop";
          };
        };

        portal = {
          enable = true;
          xdgOpenUsePortal = true;
          extraPortals =
            with pkgs;
            lib.mkForce [
              kdePackages.xdg-desktop-portal-kde
              #xdg-desktop-portal-termfilechooser
              # xdg-desktop-portal-gtk
            ];
          config = {
            common = {
              default = [
                "kde"
                # "gtk"
              ];
            };
          };
        };

        systemDirs = {
          data = [
            "/usr/share"
            "/usr/local/share"
          ];
          config = [ "/etc/xdg" ];
        };
        userDirs = {
          enable = true;
          createDirectories = true;
          setSessionVariables = true;

          desktop = "${config.home.homeDirectory}/desktop";
          documents = "${config.home.homeDirectory}/documents";
          projects = "${config.home.homeDirectory}/projects";
          download = "${config.home.homeDirectory}/downloads";
          music = "${config.home.homeDirectory}/media/music";
          pictures = "${config.home.homeDirectory}/media/pictures";
          publicShare = "${config.home.homeDirectory}/public";
          templates = "${config.home.homeDirectory}/templates";
          videos = "${config.home.homeDirectory}/media/videos";
          extraConfig = {
            SCREENSHOTS = "${config.xdg.userDirs.pictures}/screenshots";
          };
        };
        # Default paths:
        # dataHome = "~/.local/share";
        # stateHome = "~/.local/state";
        # cacheHome = "~/.cache";
        # configHome = "~/.config";

      };

      #gtk = {
      #  enable = true;
      #  # theme = {
      #  #   name = "Breeze-dark";
      #  #   package = pkgs.breeze-gtk;
      #  # };
      #  iconTheme = {
      #    name = "Breeze-dark"; package = pkgs.breeze-icons;
      #  };
      #};

      programs.joplin-desktop = {
        enable = false;
        settings."sync.target" = 2; # file-system
      };

      services.nextcloud-client = {
        enable = true;
        startInBackground = true;
      };

      xdg.configFile."mpv/input.conf".text = ''
        [ add speed -0.1
        ] add speed 0.1
      '';
    };

  ren.aspects.desktop.os =
    { pkgs, ... }:
    {
      # Graphical session (X, Wayland, display manager) and hardware (GPU, input devices) that a headless host has no
      # use for. Also X-specific packages and the generic "run any appimage" tool.

      services.xserver = {
        # Enable the X11 windowing system.
        # You can disable this if you're only using the Wayland session.
        enable = true;

        # Configure keymap in X11.
        # xkb.layout = "cz";
        # xkb.variant = "coder";
      };

      # Enable touchpad support (enabled default in most desktopManager).
      # services.xserver.libinput.enable = true;

      # Enable CUPS to print documents.
      services.printing.enable = true;

      hardware.graphics.enable = true;

      programs.appimage = {
        enable = true;
        binfmt = true;
      };

      environment.systemPackages = with pkgs; [
        xterm

        # Fix Flatpak fonts.
        xsettingsd
        xrdb
      ];

      services.flatpak.packages = [
        "it.mijorus.gearlever"
        "io.anytype.anytype"
        "com.jgraph.drawio.desktop"
        "it.mijorus.collector"
        "eu.betterbird.Betterbird"
        "com.usebottles.bottles"
        "org.zotero.Zotero"
        "re.sonny.Eloquent"
      ];
    };
}
