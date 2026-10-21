# nvchad: NvChad (nix4nvchad) neovim setup and its abbreviations.
{ ren, inputs, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.editors-nvchad = {
    homeManager =
      {
        pkgs,
        ...
      }:
      {
        imports = [
          inputs.omniflake.unified.nix4nvchad.homeManagerModules.default
        ];

        # neovim = {
        #   enable = true;
        # plugins = with pkgs.vimPlugins; [
        #   nvchad
        #   nvchad-ui
        # ];
        programs.nvchad = {
          enable = true;

          extraPackages = with pkgs; [
            #     # nodePackages.bash-language-server
            #     # docker-compose-language-service
            #     # dockerfile-language-server-nodejs
            #     # emmet-language-server
            nixd
            nixfmt
            (python3.withPackages (
              ps: with ps; [
                python-lsp-server
                flake8
                ruff
              ]
            ))
          ];

          hm-activation = true;
          backup = false;
          extraPlugins = /* lua */ ''
            return {
              --   {"equalsraf/neovim-gui-shim",lazy=false},
              {"lervag/vimtex",lazy=false},
              -- {"nvim-lua/plenary.nvim"},
              --   {
              --     'xeluxee/competitest.nvim',
              --     dependencies = 'MunifTanjim/nui.nvim',
              --     config = function() require('competitest').setup() end,
              --   },
            }
          '';
          # extraConfig = /* lua */ '''';
          # chadrdConfig = /* lua */ ''
          #   local M = {}
          #   return M
          # '';
          lazy-lock = "";
        };
      };

    abbreviations =
      { pkgs, ... }:
      let
        inherit (addax) getExeName;
      in
      with pkgs;
      {
        # n = "${getExeName neovim}";
        nv = "${getExeName neovim}";
        vim = "${getExeName neovim}";
      };
  };
}
