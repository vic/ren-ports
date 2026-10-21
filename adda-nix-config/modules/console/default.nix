# console: the base CLI toolkit (packages, fzf, alacritty, bat, btop, ...)
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  # flake-file.inputs = {
  #   nixpkgs-pkgs-update.url = "path:/home/adda/documents/it/nixos/nixpkgs-pkgs-update";
  # };

  ren.aspects.console.includes = with ren.aspects; [
    console-atuin
    console-eza
    console-intellishell
    console-terminalMultiplexers
    console-yazi
  ];

  ren.aspects.console.homeManager =
    {
      pkgs,
      ...
    }:
    {
      fonts.fontconfig.enable = true;

      home = {
        packages = with pkgs; [
          github-copilot-cli

          # Archives.
          p7zip
          unzip
          # xz
          zip
          unrar
          (addax.omni pkgs).unified.xdg-ninja.packages.default

          # Utils.
          jq # A lightweight and flexible command-line JSON processor.
          yq-go # yaml processer https://github.com/mikefarah/yq.
          treemd
          moreutils
          broot
          xcp
          # TODO: Uncomment when build succeeds
          # igrep

          # Disc usage.
          ncdu
          dua
          # duf # Modern `df`.
          dysk # Modern `df`.
          putzen

          # networking tools
          # mtr # A network diagnostic tool
          # iperf3
          # dnsutils  # `dig` + `nslookup`
          # ldns # replacement of `dig`, it provide the command `drill`
          # aria2 # A lightweight multi-protocol & multi-source command-line download utility
          # socat # replacement of openbsd-netcat
          # nmap # A utility for network discovery and security auditing
          # ipcalc  # it is a calculator for the IPv4/v6 addresses
          # iotop # io monitoring
          # iftop # network monitoring
          sshfs
          lazyssh
          # nbping

          # Misc.
          file
          which
          # tree
          # gnused
          # gnutar
          # gawk
          # zstd
          zsh-fzf-tab
          flirt

          # Development.
          # hugo # static site generator
          ast-grep
          chafa
          expect
          fd # Modern Unix `find`.
          hexyl
          just
          sd # Modern Unix `sed`.
          serpl
          srgn
          scc
          sqlit-tui

          ## Python.
          python3
          uv

          # system call monitoring
          # strace # system call monitoring
          # ltrace # library call monitoring
          # lsof # list open files

          # system tools
          # sysstat
          # lm_sensors # for `sensors` command
          # ethtool
          # pciutils # lspci
          # usbutils # lsusb
          procs # Listing a snapshot of current processes. A modern replacement for 'ps'.
          lazyjournal

          # Systemctl TUIs.
          isd
          systemctl-tui
          sysz
          lnav

          # Other.
          fastfetch
          # frogmouth # Terminal Mardown viewer.
          # thefuck
          # tldr # Modern Unix `man`.
          tealdeer

          # Trash handling.
          trash-cli
          gomi
          # trashy
          gtrash

          ueberzugpp # Terminal image viewer integration.
          # xdg-utils
          # python312Packages.xdg-base-dirs

          # Privacy.
          keepassxc
          keepass-diff
          (addax.omni pkgs).unified.tsui.packages.tsui

          (pkgs.writers.writeNuBin "current-system" /* nu */ ''
            # Inspired by https://github.com/nix-systems/current-system.
            def main [
                --json # Whether to return json
            ] {
              $"($nu.os-info.arch)-($nu.os-info.name | str replace macos darwin)"
              | (
                if $json {
                  to json
                } else {
                  $in
                }
              )
            }
          '')
        ];

        sessionVariables = {
          # PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

          TERMINAL = "alacritty";

          # Already set using programs.<program>.defaultEditor.
          # EDITOR = "hx"; # "codium", "nvim"
          # VISUAL = "hx"; # "codium", "nvim"

          SYSTEMD_EDITOR = "hx"; # "codium", "nvim"

          MANPAGER = "sh -c 'col --no-backspaces --spaces | bat --language man'";
          MANROFFOPT = "-c";
          PAGER = "bat"; # "less -FR"
        };
      };

      xdg.configFile = {
        "tig/.tigrc".text = ''
          bind status C  !git cs
          bind status A  !git ars
          bind main   P  !git p
          bind main   F !git pf

          set vertical-split =  false
        '';

        # "systemd" = {
        #   source = ../../../dotfiles/home/.config/systemd;
        #   recursive = true;
        # };
        # "ranger" = {
        # source = ../../../dotfiles/home/.config/ranger;
        # recursive = true;
        # };

        "glow/glow.yml".text = ''
          # style name or JSON path (default "auto")
          style: "auto"
          # show local files only; no network (TUI-mode only)
          local: false
          # mouse support (TUI-mode only)
          mouse: true
          # use pager to display markdown
          pager: true
          # word-wrap at width
          width: 120
        '';
      };

      programs.fzf = {
        enable = true;
        enableFishIntegration = false;
        enableNushellIntegration = false;
        historyWidget.command = "";
      };

      # Alacritty - a cross-platform, GPU-accelerated terminal emulator.
      programs.alacritty = {
        enable = true;
        settings = {
          env.TERM = "xterm-256color";
          # env.TERM = "alacritty";
          font = {
            size = 12;
            # draw_bold_text_with_bright_colors = true;
          };
          scrolling.multiplier = 5;
          selection.save_to_clipboard = true;
          window = {
            startup_mode = "Maximized";
            # padding = {
            #   x = 6;
            #   y = 6;
            # };
            # dynamic_padding = true;
          };
          keyboard.bindings =
            let
              # Nix has no \x/\u escape in string literals; decode via JSON to get a real ESC (0x1B) byte.
              esc = builtins.fromJSON ''"\u001b"'';
            in
            [
              # Claude Code (and other TUIs) read Shift+Enter as ESC CR to insert a
              # newline instead of submitting. This is what `claude`'s `/terminal-setup`
              # tries to write for Alacritty, but it emits an invalid TOML escape there;
              # doing it declaratively here avoids that bug.
              {
                key = "Return";
                mods = "Shift";
                chars = "${esc}\r";
              }
            ];
        };
      };

      # Nicely reload system units when changing configs
      #systemd.user.startServices = lib.mkIf isLinux "sd-switch";

      programs.pay-respects = {
        enable = false;
      };

      programs.navi = {
        enable = true;
        settings = { };
      };

      programs.uv = {
        enable = true;
        settings = {
          preview = true;
          pip = {
            allow-empty-requirements = true;
            all-extras = true;
            strict = true;
            verify-hashes = true;
          };
        };
      };

      programs.bat = {
        enable = true;
        config = {
          pager = "less --quit-if-one-screen --RAW-CONTROL-CHARS";
        };
        extraPackages = with pkgs.bat-extras; [
          batdiff
          batgrep
          batman
          batpipe
          batwatch
          prettybat
        ];
      };

      programs.wallust = {
        enable = true;
        # settings = { };
      };

      programs.television = {
        enable = true;
        # settings = { };
        # channels = { };
      };

      programs.clock-rs = {
        enable = true;
        # settings = {};
      };

      # services.home-manager.autoExpire = ...;

      xdg.terminal-exec = {
        enable = true;
        settings = {
          default = [
            "Alacritty.desktop"
          ];
        };
      };

      programs.tray-tui = {
        enable = true;
        settings = {
          sorting = true;
          # columns = 3;
          mouse = true;
        };
      };

      programs.ripgrep.enable = true;
      programs.ripgrep-all.enable = true;

      programs.btop = {
        enable = true;
        settings = {
          vim_keys = true;
          proc_tree = true;
          proc_left = true;
          proc_aggregate = true;
        };
      };

      programs.atool = {
        enable = true;
        settings = {
          path_unrar = "unrar-free";
        };
        extraPackages = with pkgs; [
          file
          gnutar
          gzip
          bzip2
          cpio
          lhasa
          lzop
          p7zip
          unrar-free
          unzip
          xz
          zip
        ];
      };
    };
}
