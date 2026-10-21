# second file of dev-editor-nvf: visuals, ui and plugin toggles.
{ ... }:
{
  ren.aspects.dev-editor-nvf.homeManager.programs.nvf.settings.vim = {
    visuals = {
      nvim-web-devicons.enable = true;
      cinnamon-nvim.enable = true;
      fidget-nvim.enable = true;
      highlight-undo.enable = false;
      indent-blankline.enable = true;
      nvim-cursorline = {
        enable = true;
        setupOpts.line_timeout = 0;
      };
    };

    statusline.lualine.enable = true;

    autopairs.nvim-autopairs.enable = true;
    autocomplete.nvim-cmp.enable = true;

    tabline.nvimBufferline.enable = true;
    treesitter.context.enable = true;

    binds = {
      whichKey.enable = true;
      cheatsheet.enable = true;
    };
    telescope.enable = true;

    git = {
      enable = true;
      gitsigns.enable = true;
      gitsigns.codeActions.enable = false;
    };

    minimap.minimap-vim.enable = false;
    dashboard.startify.enable = true;

    notify.nvim-notify.enable = true;
    utility = {
      diffview-nvim.enable = true;
      motion = {
        hop.enable = true;
        leap.enable = true;
        precognition.enable = true;
      };
    };

    notes.todo-comments.enable = true;
    comments.comment-nvim.enable = true;

    terminal.toggleterm = {
      enable = true;
      lazygit.enable = true;
    };

    ui = {
      borders.enable = true;
      noice.enable = true;
      colorizer.enable = true;
      illuminate.enable = true;
      modes-nvim.enable = false;
      smartcolumn = {
        enable = true;
        setupOpts.custom_colorcolumn = {
          nix = "110";
          ruby = "120";
          java = "130";
          go = [
            "90"
            "130"
          ];
        };
      };
      fastaction.enable = true;
      breadcrumbs = {
        enable = true;
        navbuddy.enable = true;
      };
    };

    assistant = {
      chatgpt.enable = false;
      copilot.enable = false;
    };

    session.nvim-session-manager.enable = false;
    gestures.gesture-nvim.enable = false;
    presence.neocord.enable = false;
  };
}
