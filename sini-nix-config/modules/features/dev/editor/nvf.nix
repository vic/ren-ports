{ inputs, ... }:
{
  ren.aspects.dev-editor-nvf = {
    homeManagerModules = [
      inputs.nvf.homeManagerModules.default
    ];

    homeManager = {
      programs.nvf = {
        enable = true;
        settings.vim = {
          theme.enable = true;
          options = {
            tabstop = 2;
            shiftwidth = 2;
            softtabstop = 2;
            expandtab = false;
          };
          maps = {
            normal."<leader><Left>" = {
              silent = true;
              action = "<cmd>bprev<CR>";
            };
            normal."<leader><Right>" = {
              silent = true;
              action = "<cmd>bnext<CR>";
            };
            visual."<" = {
              action = "<gv";
              desc = "Unindent and reselect";
            };
            visual.">" = {
              action = ">gv";
              desc = "Indent and reselect";
            };
          };
          viAlias = true;
          vimAlias = true;
          preventJunkFiles = true;

          debugMode.enable = false;

          lsp = {
            enable = true;
            formatOnSave = true;
            lightbulb.enable = true;
            trouble.enable = true;
            lspSignature.enable = true;
          };

          debugger.nvim-dap = {
            enable = true;
            ui.enable = true;
          };

          languages = {
            enableFormat = true;
            enableTreesitter = true;
            enableExtraDiagnostics = true;
            nix = {
              enable = true;
              format = {
                enable = true;
                type = [ "nixfmt" ];
              };
              lsp = {
                enable = true;
                servers = [ "nixd" ];
                # gen-lsp follow-up: nixd.settings.options.den.expr -> den-lsp.options.den; inert until the pin carries gen-lsp, option path version-specific.
              };
              treesitter.enable = true;
            };

            markdown.enable = true;
            bash.enable = true;
            python.enable = true;
            css.enable = true;
            rust.enable = true;
          };
        };
      };

      home.sessionVariables = {
        EDITOR = "nvim";
      };
    };
  };
}
