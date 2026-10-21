# nix: nixpkgs-maintainer Nix toolkit (nixd, nil, omnix, nix-init, nom wrappers, devenv, nh, angrr) and editor wiring.
{ ren, inputs, ... }:
let
  addax = ren.helpers;
  inherit (addax) getExeName;
in
{

  # Determinate Nix, direnv and envoluntary are prerequisites rather than part of the maintainer toolkit below, and
  # a headless host needs them without the rest; they live in ./nix-core.nix and are pulled back in here so this aspect
  # is still the whole set for a workstation.
  ren.aspects.languages-nix.includes = [ ren.aspects.languages-nix-core ];

  ren.aspects.languages-nix.vscodiumSettings = {
    "[nix]" = {
      editor = {
        tabSize = 2;
        formatOnSave = true;
        defaultFormatter = "jnoortheen.nix-ide";
      };
    };
    nix = {
      # Nix configurations.
      enableLanguageServer = true;
      # "nix.serverPath" = "rnix-lsp";
      # "nix.serverPath" = "nil";
      serverPath = "nixd";
      serverSettings = {
        # settings for 'nil' LSP
        nil = {
          diagnostics = {
            ignored = [
              "unused_binding"
              "unused_with"
            ];
          };
          formatting = {
            command = [
              # "nixpkgs-fmt"
              "nix fmt"
            ];
          };
        };
        # settings for 'nixd' LSP
        # "nixd" = ;
        #     "eval" = ;
        #         # stuff
        #     },
        #     "formatting" = ;
        #         "command" = "nixpkgs-fmt;
        #     },
        #     "options" = ;
        #         "enable" = true;
        #         "target" = ;
        #             # tweak arguments here
        #             "args" = [];
        #             # NixOS options
        #             "installable" = "<flakeref>#nixosConfigurations.<name>.options;

        #             # Flake-parts options
        #             # "installable" = "<flakeref>#debug.options;

        #             # Home-manager options
        #             # "installable" = "<flakeref>#homeConfigurations.<name>.options;
        #         }
        #     }
        # }
      };
    };
  };

  ren.aspects.languages-nix.vscodium-extensions = { ... }: [
    "bbenoist.nix"
    # vscode-marketplace.arrterian.nix-env-selector"
    "jnoortheen.nix-ide"
    "b4dm4n.nixpkgs-fmt"
    # vscode-marketplace.brettm12345.nixfmt-vscode"
    "mkhl.direnv"
    "datakurre.devenv"
    "arrterian.nix-env-selector"

  ];

  ren.aspects.languages-nix.helixLanguages =
    { pkgs, ... }:
    {
      language = [
        {
          name = "nix";
          auto-format = true;
          language-servers = [
            "nixd"
            "nil"
            "statix"
            "deadnix"
          ];
          roots = [
            "flake.nix"
            "shell.nix"
            "default.nix"
          ];
          formatter = {
            command = getExeName pkgs.nixfmt;
          };
        }
      ];

      grammar = [
        {
          name = "nix";
          source = {
            git = "https://github.com/nix-community/tree-sitter-nix";
            rev = "21897cc3dcd15325303e46b85295b743742af6ab";
          };
        }
      ];

      language-server = {
        nil = {
          command = getExeName pkgs.nil;
          # command = getExeName inputs'.nil.packages.nil;
          config = {
            nil.nix = {
              maxMemoryMB = 5120; # 2560
              flake = {
                autoArchive = true;
                autoEvalInputs = true;
              };
            };
          };
        };

        statix = {
          command = getExeName pkgs.statix;
          args = [
            "check"
            "--stdin"
            "--format"
            "errfmt"
          ];
          #   # command = "efm-langserver";
          #   config = {
          #     languages = {
          #       nix = [
          #         {
          #           # https://github.com/creativenull/efmls-configs-nvim/blob/ddc7c542aaad21da594edba233c15ae3fad01ea0/lua/efmls-configs/linters/statix.lua
          #           lintCommand = "statix check --stdin --format=errfmt";
          #           lintStdIn = true;
          #           lintIgnoreExitCode = true;
          #           lintFormats = [ "<stdin>>%l:%c:%t:%n:%m" ];
          #           rootMarkers = [
          #             "flake.nix"
          #             "shell.nix"
          #             "default.nix"
          #           ];
          #         }
          #       ];
          #     };
          #   };
        };

        # nixd = {
        #   command = getExeName pkgs.nixd;
        #   args = [
        #     "--semantic-tokens=true"
        #   ];
        #   config.nixd =
        #     let
        #       myFlake = ''(builtins.getFlake "${config.programs.nh.flake})'';
        #       nixosOpts = "${myFlake}.nixosConfigurations.${host.hostName}.options";
        #     in
        #     {
        #       nixpkgs.expr = "import ${myFlake}.inputs.nixpkgs { }";
        #       formatting.command = [ "${getExe pkgs.nixfmt}" ];
        #       options = {
        #         nixos.expr = nixosOpts;
        #         home-manager.expr = "${nixosOpts}.home-manager.users.type.getSubOptions []";
        #       };
        #     };
        # };

        # deadnix = {
        #   command = getExeName pkgs.deadnix;
        # };
      };
    };

  ren.aspects.languages-nix.zed-extensions = { ... }: [
    "nix"
  ];

  ren.aspects.languages-nix.zedPackages = { pkgs, ... }: with pkgs;
    [
      nixd
      nixfmt
      nil
    ];

  ren.aspects.languages-nix.zedSettings = {
    languages.Nix = {
      tab_size = 2;
      formatter = {
        language_server = {
          name = "nixd";
        };
      };
      language_servers = [
        "nixd"
        "nil"
      ];
    };
    lsp.nixd = {
      settings = {
        nixd = {
          formatting = {
            command = [ "nixfmt" ];
          };
          nixpkgs = {
            expr = ''(builtins.getFlake "/home/adda/.nixos-config").inputs.nixpkgs {}'';
          };
        };
      };
    };
  };

  # pedantix parses with tree-sitter-nix, whose grammar predates RFC 148: every file using `|>`/`<|` — this repo has
  #  several — comes out as a parse error and is refused. The patch masks the pipe operators for the parse only, so the
  #  reordering passes keep working on the real source. Dropped once the grammar learns pipes.
  ren.aspects.pkg-pedantix = {
    at = ren.system.x86_64-linux;
    packages =
      { system, ... }:
      let
        pkgs = system.legacyPackages;
        pedantixPatched =
          inputs.omniflake.unified.pedantix.packages.${pkgs.stdenv.hostPlatform.system}.pedantix.overrideAttrs
            (prevAttrs: {
              patches = (prevAttrs.patches or [ ]) ++ [ ./pedantix-pipe-operators.patch ];
            });
      in
      {
        # Upstream's `pedantix-wrapped` closes over the unpatched derivation, so the wrapper is rebuilt here rather than
        #  overridden: pedantix shells out to its base formatter by name and needs one on PATH.
        pedantix = pkgs.writeShellApplication {
          name = "pedantix";
          runtimeInputs = [
            pedantixPatched
            pkgs.alejandra
            pkgs.nixfmt
            pkgs.nixpkgs-fmt
          ];
          text = ''exec pedantix "$@"'';
        };
      };
  };

  ren.aspects.languages-nix.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # The single 'nix' entry point behind the fish and nushell wrappers below: route every subcommand
      #  'nix-output-monitor' can wrap through it, and make everything else at least print build logs and be
      #  verbose. Written once as a script rather than twice in fish and nushell, so the routing table has one
      #  home; all a shell has to add is its own name, which is the only thing 'nix-your-shell' needs to re-enter
      #  it inside 'nix develop'/'nix shell'.
      #
      #  'nix' is deliberately looked up in PATH instead of by store path: this config runs Determinate Nix,
      #  which is newer than 'pkgs.nix', so pinning the store path here would silently downgrade the CLI.
      nixWrapper = pkgs.writeShellApplication {
        name = "nix-nom";
        runtimeInputs = [
          pkgs.nix-output-monitor
          config.programs.nix-your-shell.package
        ];
        text = ''
          shell=$1
          shift

          # Which nix subcommand is this? The first argument that isn't a flag, stopping at '--' (everything
          #  past it belongs to the program that 'nix run'/'nix develop' invokes, not to nix). A flag *value*
          #  that happens to look like a subcommand ('nix --option keep-going build') is misread as one, and
          #  then lands in the plain-nix branch below -- the harmless direction to be wrong in.
          args=("$@")
          subcommand=
          index=0
          for arg in "''${args[@]}"; do
            case $arg in
              --) break ;;
              -*) ;;
              *)
                subcommand=$arg
                break
                ;;
            esac
            index=$((index + 1))
          done

          # 'nom' recognises the subcommand only as its very first argument, so hoist it in front of any global
          #  flags the caller put before it ('nix --print-build-logs build .#x'). Nix takes those flags in
          #  either position, so this does not change what runs.
          nom_args=("$subcommand" "''${args[@]:0:index}" "''${args[@]:index + 1}")

          case $subcommand in
            # 'nix-your-shell' runs these through 'nom' itself, and re-enters this shell instead of bash.
            develop | shell)
              exec nix-your-shell --nom "$shell" nix -- "''${nom_args[@]}"
              ;;
            # Wrapped by 'nom', but not by 'nix-your-shell'.
            build | copy | flake)
              exec nom "''${nom_args[@]}"
              ;;
            # Whatever 'nom' cannot wrap: ask nix itself for build logs and verbose output.
            *)
              exec nix --print-build-logs --verbose "$@"
              ;;
          esac
        '';
      };
    in
    {
      imports = [
        inputs.omniflake.unified.pedantix.homeModules.default
        inputs.omniflake.unified.nix-index-database.homeModules.nix-index
      ];

      home.packages = with pkgs; [
        nix-search
        nix-run
        # nix-bundle
        (addax.omni pkgs).unified.nix-sweep.packages.default
        nix-output-monitor # It provides the command `nom`. Works just like `nix` with more detailed log output.
        nixd
        nil
        nix-du
        nix-melt
        nix-inspect # Interactive tui for inspecting nix configs.
        nix-olde # Show details about outdated packages in your NixOS system.
        (addax.omni pkgs).unified.nix_version_search_cli.packages.default
        (addax.omni pkgs).unified.flint.packages.default
        omnix
        nvd # nix-version-diff
        dix # nix diff
        nixpkgs-reviewFull
        nix-update
        nix-tree
        nurl
        treefmt

        # Referenced by name from the `helixLanguages` language config below:
        #  formatter plus the two non-LSP-package servers.
        nixfmt
        statix
        deadnix
      ];

      programs.pedantix = {
        enable = true;
        package = (addax.selfPackages pkgs).pedantix;
        settings = {
          attrs = {
            sort = false;
          };
          inherits = {
            sort = true;
          };
        };
      };

      programs.flake-edit = {
        enable = true;
        settings = {
          # https://github.com/a-kenji/flake-edit

          # Configuration for `flake-edit follow [PATHS]`
          follow = {
            # Inputs to ignore. Supports two formats:
            #   - Full path: "crane.nixpkgs" - ignores only that specific nested input
            #   - Simple name: "systems" - ignores all nested inputs with that name
            # ignore = ["systems", "crane.flake-utils"]

            # Minimum number of transitive follows required to add a top-level follows input.
            # Set to 0 to disable transitive follows deduplication.
            # transitive_min = 2

            # Alias mappings.
            # Key is the canonical name (must exist at top-level), values are alternatives.
            # Example: if nested input is "nixpkgs-lib" and top-level "nixpkgs" exists,
            # follow will suggest: poetry2nix.nixpkgs-lib -> nixpkgs
            aliases = {
              nixpkgs = [ "nixpkgs-lib" ];
            };

            # Maximum depth of follows declarations to write.
            # Unset (the default) writes follows at every depth the lockfile graph
            # supports. Set an explicit number to cap the depth: 1 writes only
            # `parent.nested.follows = "target"`, 2 also writes
            # `parent.middle.grandchild.follows = "target"`, and so on.
            # max_depth = 1
          };
        };
      };

      programs.nix-search-tv = {
        enable = true;
        enableTelevisionIntegration = true;
        settings = {
          # indexes = [
          #   "nixos"
          #   "nixpkgs"
          #   "home-manager"
          #   "nur"
          # ];

          # experimental = {
          #   render_docs_indexes = {
          #     # nvf = "https://notashelf.github.io/nvf/options.html";
          #   };
          # };
        };
      };

      programs.nix-your-shell = {
        enable = true;
        nix-output-monitor.enable = true;
        # The 'nix' function these integrations generate routes only 'build', 'shell' and 'develop' through
        #  'nom' and adds nothing at all to any other subcommand, so fish and nushell call 'nix-your-shell'
        #  through the wrapper above instead. Zsh keeps the generated integration.
        enableFishIntegration = false;
        enableNushellIntegration = false;
      };

      programs.fish.functions = {
        # 'wraps' keeps the completions generated for the real binary working for the function too.
        nix = {
          description = "nix, through nix-output-monitor where possible";
          wraps = "nix";
          body = "${lib.getExe nixWrapper} fish $argv";
        };
        nix-shell = {
          description = "nix-shell, through nix-output-monitor";
          wraps = "nix-shell";
          body = "${lib.getExe config.programs.nix-your-shell.package} --nom fish nix-shell -- $argv";
        };
        nix-build = {
          description = "nix-build, through nix-output-monitor";
          wraps = "nix-build";
          body = "${lib.getExe' pkgs.nix-output-monitor "nom-build"} $argv";
        };
      };

      # The same three wrappers for nushell. '@complete external' keeps the external completer (carapace)
      #  completing them like the binaries they wrap.
      programs.nushell.extraConfig = /* nu */ ''
        # Run nix through nix-output-monitor where possible, and verbosely everywhere else.
        @complete external
        def --wrapped nix [...args] {
          ^${lib.getExe nixWrapper} nu ...$args
        }

        @complete external
        def --wrapped nix-shell [...args] {
          ^${lib.getExe config.programs.nix-your-shell.package} --nom nu nix-shell -- ...$args
        }

        @complete external
        def --wrapped nix-build [...args] {
          ^${lib.getExe' pkgs.nix-output-monitor "nom-build"} ...$args
        }
      '';

      programs.nix-init = {
        enable = true;
        settings = {
          # nixpkgs = "<nixpkgs>";
          # nixpkgs = "nixpkgs"; # use the nixpkgs from the flake registry
          commit = true;
          maintainers = [
            "adda"
          ];
          access-tokens = {
            #   "github.com" = "ghp_blahblahblah...";
            #   "gitlab.com".command = ["secret-tool", "or", "whatever", "you", "use"]
            # "gitlab.gnome.org".file = "/path/to/api/token"
          };
        };
      };

      programs.nix-index = {
        enable = true;
      };
      programs.nix-index-database = {
        # Run uninstalled applications dicertly by prefixing the command with ',', e.g., ', cowsay "Hello."'.
        comma.enable = true;
      };
      # command-not-found = {
      #   enable = true;
      # };

      # yet-another-nix-helper
      programs.nh = {
        enable = true;
        clean = {
          enable = true;
          extraArgs = "--keep-since 7d --keep 3";
        };
        flake = "${config.home.homeDirectory}/.nixos-config";
      };

      # TODO: To set in overlays: devenv = (addax.omni pkgs).unified.devenv.packages.default;
      programs.devenv = {
        enable = true;

        # devenv's per-prompt cd-hooks (`devenv hook <shell>`) auto-`exec devenv shell` in any directory
        # holding a devenv.nix. That duplicates the `use devenv` activation below and, in nushell, loops
        # forever: `programs.direnv-instant`'s pre_prompt hook re-applies its cached direnv unload payload
        # (which lists DEVENV_ROOT, DEVENV_PROFILE, PATH, CC, ... as null) in *every* shell, so inside a
        # devenv shell it strips DEVENV_ROOT; devenv's hook then concludes it is not in a devenv shell and
        # spawns another one, nesting without bound. direnv stays the single activation mechanism.
        enableBashIntegration = false;
        enableFishIntegration = false;
        enableNushellIntegration = false;
        enableZshIntegration = false;
      };

      # devenv's direnvrc (`use devenv`) execs `$DEVENV_BIN`, falling back to `command -v devenv`. Point it at a
      #  quiet wrapper so a successful activation prints nothing:
      #   - `--quiet` selects `VerbosityLevel::Quiet`, which only renders `ActivityLevel::Error`, dropping the
      #     "Configuring shell"/"Building shell" Info activities and the enterShell task table.
      #   - `--no-tui` drops the spinner, which devenv would otherwise draw because direnv leaves it a tty.
      # Interactive `devenv` invocations are untouched; only the direnv activation path goes through this.
      home.sessionVariables.DEVENV_BIN = pkgs.writeShellScript "devenv-quiet" ''
        exec ${lib.getExe config.programs.devenv.package} --quiet --no-tui "$@"
      '';
    };

  # Determinate Nix 3.23 logs activity type 10113, which nom 2.2.0 rejects with a ParseNixJSONMessageError per message.
  #  Backport of maralorn/nix-output-monitor#321 (unmerged); drop once omniflake pins a release with it. A flake-level
  #  overlay because the devshell's pkgs (../../../packages.nix) need it too: its `nh` runs `just switch`.
  ren.aspects.languages-nix.overlays = { ... }: _final: prev: {
    nix-output-monitor =
      inputs.omniflake.unified.nix-output-monitor.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs
        (prevAttrs: {
          patches = (prevAttrs.patches or [ ]) ++ [ ./nix-output-monitor-unknown-activity-types.patch ];
        });
  };

  ren.aspects.languages-nix.os = {
    services.angrr = {
      enable = true;
      # enableNixGcIntegration = true;
      settings = {
        #       temporary-root-policies = {
        #   direnv = {
        #     path-regex = "/\\.direnv/";
        #     period = "14d";
        #   };
        #   result = {
        #     path-regex = "/result[^/]*$";
        #     period = "3d";
        #   };
        #   # You can define your own policies
        #   # ...
        # };
        # profile-policies = {
        #   system = {
        #     profile-paths = [ "/nix/var/nix/profiles/system" ];
        #     keep-since = "14d";
        #     keep-latest-n = 5;
        #     keep-booted-system = true;
        #     keep-current-system = true;
        #   };
        #   user = {
        #     enable = false; # Policies can be individually disabled
        #     profile-paths = [
        #       # `~` at the beginning will be expanded to the home directory of each discovered user
        #       "~/.local/state/nix/profiles/profile"
        #       "/nix/var/nix/profiles/per-user/root/profile"
        #     ];
        #     keep-since = "1d";
        #     keep-latest-n = 1;
        #   };
        #   # You can define your own policies
        #   # ...
        # };
      };
    };

    # TODO: Configure global direnv options.
    #  - dotenv
    #   programs.direnv = {
    #     enable = true;
    #     nix-direnv = {
    #       enable = true;
    #     };
    #     settings = {
    #     };
    #     direnvrcExtra = "";
    #   };
  };
}
