# Base: what every host gets (den.default.nixos): nix settings, unfree, overlays pool, boot, ssh, locale, shells.
{ ren, inputs, ... }:
{
  ren.aspects.base = {
    at = ren.kinds.host;
    nixos =
      {
        lib,
        overlays,
        pkgs,

        ...
      }:
      {
        imports = [
          # Adds the NUR overlay
          inputs.omniflake.unified.nur.modules.nixos.default
          # NUR modules to import
          # inputs.omniflake.unified.nur.legacyPackages."${system}".repos.iopq.modules.xraya
          # This adds the NUR nixpkgs overlay.
          # Example:
          # ({ pkgs, ... }: {
          #   environment.systemPackages = [ pkgs.nur.repos.mic92.hello-nur ];
          # })
        ];

        # FIXME: Would be nice to have, but fails too often.
        systemd.enableStrictShellChecks = false;

        nixpkgs = {
          overlays =
            let
              # When applied, the stable nixpkgs set (declared in the flake inputs) will
              # be accessible through 'pkgs.stable'
              stablePackages = final: _: {
                stable =
                  import (inputs.omniflake.unified.nixpkgs-multiverse.${final.stdenv.hostPlatform.system}.at "26.05")
                    {
                      inherit (final.stdenv.hostPlatform) system;
                      inherit (final) config;
                    };
              };
            in
            [
              # Add overlays your own flake exports (from overlays and pkgs dir):
              # inputs.self.overlays.additions
              # inputs.self.overlays.modifications
              stablePackages

              # inputs.omniflake.unified.nur.overlays.default

              # You can also add overlays exported from other flakes:
              # neovim-nightly-overlay.overlays.default
              #inputs.agenix.overlays.default

              # Or define it inline, for example:
              # (final: prev: {
              #   hi = final.hello.overrideAttrs (oldAttrs: {
              #     patches = [ ./change-hello-to-hi.patch ];
              #   });
              # })
            ]
            # Overlays contributed by aspects via the `nixpkgsOverlays` quirk.
            # Applies to home-manager's pkgs too, since `home-manager.useGlobalPkgs = true`.
            ++ overlays;
          config = {
            # Disable if you don't want unfree packages
            allowUnfree = true;
            allowUnfreePredicate = _: true;
          };
        };

        # system = {
        #   autoUpgrade = {
        #     enable = true;
        #     flake = "file+git://~/.nixos-config";
        #   };
        # };

        nix =
          # let
          #   flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
          # in
          {
            # package =
            #   lib.mkForce
            #     # pkgs.nix;
            #     # pkgs.nixVersions.latest;
            #     # pkgs.lixPackageSets.latest.lix;
            #     inputs.omniflake.pinned.determinate.packages.${pkgs.stdenv.hostPlatform.system}.default;

            # This will add each flake input as a registry
            # To make nix3 commands consistent with your flake
            # registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
            #   # (lib.filterAttrs (_: lib.isType "flake"))
            #   inputs
            # );

            # Garbage collecting.
            # gc = {
            #   automatic = true;
            #   dates = "weekly";
            #   options = "--delete-older-than 7d";
            # };

            settings = {
              experimental-features = [
                "auto-allocate-uids"
                "blake3-hashes"
                "ca-derivations"
                "cgroups"
                "dynamic-derivations"
                "fetch-closure"
                "fetch-tree"
                "flakes"
                "git-hashing"
                "impure-derivations"
                #"local-overlay-store"
                "nix-command"
                "parse-toml-timestamps"
                "pipe-operators"
                # "pipe-operator"
                "read-only-local-store"
                "recursive-nix"
                # "repl-automation"
                # Mounted SSH store (`mounted-ssh-store`)
                # Local overlay store (`local-overlay-store`)
                # Allow impure environment variables in the execution environment (`configurable-impure-env`)
                # Allow forcing trust settings for the Nix daemon (`daemon-trust-override`)
              ];

              auto-allocate-uids = true;

              # Deduplicate and optimize nix store
              auto-optimise-store = true;

              # Opinionated: disable global registry
              #flake-registry = "";
              # Workaround for https://github.com/NixOS/nix/issues/9574
              # nix-path = config.nix.nixPath;

              # `lazy-trees` is not here: it is a Determinate Nix setting, and upstream
              #  nix refuses to start with it. It lives in modules/aspects/development/
              #  languages/nix-core.nix, which is what installs Determinate Nix.

              lint-url-literals = "fatal";
              # lint-short-path-literals = "warn";
              # lint-absolute-path-literals = "warn";

              warn-dirty = false;

              max-jobs = "auto"; # Use all available CPU cores for building packages.

              # Avoid unwanted garbage collection when using nix-direnv.
              keep-outputs = true;
              keep-derivations = true;

              trusted-users = [
                "root"
                "@wheel"
              ];
            };
            # Completely disable channels.
            channel.enable = false;

            # Opinionated: make flake registry and nix path match flake inputs
            # This will add each flake input as a registry
            # To make nix3 commands consistent with your flake
            # registry = lib.mapAttrs (_name: flake: { inherit flake; }) flakeInputs;

            # This will add each flake input as a registry
            # To make nix3 commands consistent with your flake
            # registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

            # This will add each flake input as a registry
            # To make nix3 commands consistent with your flake
            # registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
            #   (lib.filterAttrs (_: lib.isType "flake")) inputs
            # );

            # nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
            # This will additionally add your inputs to the system's legacy channels
            # Making legacy nix commands consistent as well, awesome!
            # nixPath = [ "/etc/nix/path" ];
          };
        # environment.etc = (
        #   lib.mapAttrs' (name: value: {
        #     name = "nix/path/${name}";
        #     value.source = value.flake;
        #   }) config.nix.registry
        # )

        # Bootloader.
        boot = {
          loader = {
            systemd-boot.enable = lib.mkForce false;
            grub = {
              enable = lib.mkForce true;
              #device = "/dev/nvme0n1p5";
              device = "nodev";
              efiSupport = true;
              #efiInstallAsRemovable = true; # in case canTouchEfiVariables doesn't work for your system
              useOSProber = true;
              configurationLimit = 10;
            };
            efi = {
              canTouchEfiVariables = true;
              efiSysMountPoint = "/boot/efi";
            };
            timeout = null; # Remain in boot menu indefinitely.
          };
          # kernelPackages = pkgs.linuxPackages_latest;
          extraModulePackages = [
            # pkgs.linuxPackages_zen.kernel
            # pkgs.linuxPackages_latest.kernel
          ];
          # initrd.kernelModules = [
          #   "amdgpu"
          # ];
        };

        # This setups a SSH server. Very important if you're setting up a headless system.
        # Feel free to remove if you don't need it.
        services.openssh = {
          enable = true;
          settings = {
            # Forbid root login through SSH.
            PermitRootLogin = "no";
            # Use keys only. Remove if you want to SSH using password (not recommended)
            PasswordAuthentication = false;
            # PasswordAuthentication alone does not get rid of password login: NixOS
            #  leaves KbdInteractiveAuthentication at its upstream default of true, and
            #  sshd's PAM stack answers that challenge with pam_unix, so `ssh` still
            #  offers "keyboard-interactive" and still takes the account password. The
            #  banner on this tree's hosts said so: "Permission denied
            #  (publickey,password,keyboard-interactive)".
            KbdInteractiveAuthentication = false;

            X11Forwarding = true;
          };

          openFirewall = true;
        };

        services.envfs = {
          enable = true;
          extraFallbackPathCommands = ''
            ln -s ${pkgs.bash}/bin/bash $out/bash
          '';
        };

        # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

        # Configure network proxy if necessary
        # networking.proxy.default = "http://user:password@proxy:port/";
        # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

        # Set your time zone.
        time.timeZone = "Europe/Prague";

        # Select internationalisation properties.
        i18n.defaultLocale = lib.mkForce "en_GB.UTF-8";

        i18n.extraLocaleSettings = {
          LC_ADDRESS = "cs_CZ.UTF-8";
          LC_IDENTIFICATION = "cs_CZ.UTF-8";
          LC_MEASUREMENT = "cs_CZ.UTF-8";
          LC_MONETARY = "cs_CZ.UTF-8";
          LC_NAME = "cs_CZ.UTF-8";
          LC_NUMERIC = "cs_CZ.UTF-8";
          LC_PAPER = "cs_CZ.UTF-8";
          LC_TELEPHONE = "cs_CZ.UTF-8";
          LC_TIME = "cs_CZ.UTF-8";
          LC_DATE = "en_US.UTF-8";
        };

        # List packages installed in system profile. To search, run:
        # $ nix search wget
        environment = {
          defaultPackages = [ ]; # "Historical mistake". Removes pkgs.{strace,rsync,perl} from installed packages.
          systemPackages = with pkgs; [
            git
            gnupg
            killall
            pciutils
            rsync
            usbutils
            wget

            # nur.repos.mic92.hello-nur
          ];

          shells = with pkgs; [
            bash
            zsh
            fish
            dash
          ];
        };

        programs.nano.enable = false;

        programs.zsh.enable = true;
        programs.fish = {
          enable = true;
          # vendor = {
          #   completions.enable = true;
          #   config.enable = true;
          #   functions.enable = true;
          # };
        };
        users.defaultUserShell = pkgs.dash;

        # Some programs need SUID wrappers, can be configured further or are
        # started in user sessions.
        # programs.mtr.enable = true;
        programs.gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
        };

        services.fstrim = {
          enable = true;
          #interval = "weekly"; # The default.
        };

        # security.polkit.extraConfig = ''
        #   polkit.addRule(function(action, subject) {
        #     if (action.id == "org.freedesktop.fwupd.refresh-remote" &&
        #         subject.isInGroup("wheel")) {
        #       return polkit.Result.YES;
        #     }
        #   });
        # '';
        #
        # Allow fwupd-refresh to restart if failed (after resume)
        # systemd.services.fwupd-refresh = {
        #   serviceConfig = {
        #     Restart = "on-failure";
        #     RestartSec = "20";
        #   };
        #   unitConfig = {
        #     StartLimitIntervalSec = 100;
        #     StartLimitBurst = 5;
        #   };
        # };
      };
  };
}
