# yazi: terminal file manager with plugins and keymap
{ ren, ... }:
{
  ren.aspects.console-yazi.homeManager =
    { pkgs, ... }:
    {
      programs.yazi = {
        enable = true;
        shellWrapperName = "yy";
        settings = {
          mgr = {
            show_hidden = true;
            sort_by = "mtime";
            sort_dir_first = true;
            sort_reverse = true;
          };
        };
        plugins = {
          inherit (pkgs.yaziPlugins)
            git
            diff
            glow
            lsar
            nord
            ouch
            sudo
            chmod
            dupes
            gitui
            mount
            piper
            # rsync
            bypass
            duckdb
            # mactag
            miller
            lazygit
            jjui
            restore
            yatline
            compress
            mime-ext
            projects
            starship
            bookmarks
            mediainfo
            # no-status
            vcs-files
            full-border
            recycle-bin
            smart-enter
            smart-paste
            time-travel
            toggle-pane
            jump-to-char
            rich-preview
            smart-filter
            wl-clipboard
            yatline-githead
            relative-motions
            # yatline-catppuccin
            # nur.repos.xyenon.yaziPlugins.fg
            # nur.repos.xyenon.yaziPlugins.ouch
            # nur.repos.xyenon.yaziPlugins.yafg
            # nur.repos.Vortriz.yaziPlugins.gvfs
            # nur.repos.Vortriz.yaziPlugins.bunny
            # nur.repos.Vortriz.yaziPlugins.office
            # nur.repos.xyenon.yaziPlugins.clipboard
            # nur.repos.xyenon.yaziPlugins.exifaudio
            # nur.repos.Vortriz.yaziPlugins.what-size
            # nur.repos.xyenon.yaziPlugins.yazi-rs.git
            # nur.repos.xyenon.yaziPlugins.yazi-rs.diff
            # nur.repos.xyenon.yaziPlugins.yazi-rs.lsar
            # nur.repos.xyenon.yaziPlugins.yazi-rs.zoom
            # nur.repos.Vortriz.yaziPlugins.custom-shell
            # nur.repos.xyenon.yaziPlugins.yazi-rs.chmod
            # nur.repos.xyenon.yaziPlugins.yazi-rs.mount
            # nur.repos.xyenon.yaziPlugins.yazi-rs.piper
            # nur.repos.xyenon.yaziPlugins.yazi-rs.types
            # nur.repos.Vortriz.yaziPlugins.enhance-piper
            # nur.repos.xyenon.yaziPlugins.yazi-rs.mactag
            # nur.repos.xyenon.yaziPlugins.yazi-rs.mime-ext
            # nur.repos.xyenon.yaziPlugins.yazi-rs.no-status
            # nur.repos.xyenon.yaziPlugins.yazi-rs.sudo-demo
            # nur.repos.xyenon.yaziPlugins.yazi-rs.vcs-files
            # nur.repos.Vortriz.yaziPlugins.hover-after-moved
            # nur.repos.xyenon.yaziPlugins.yazi-rs.full-border
            # nur.repos.xyenon.yaziPlugins.yazi-rs.smart-enter
            # nur.repos.xyenon.yaziPlugins.yazi-rs.smart-paste
            # nur.repos.xyenon.yaziPlugins.yazi-rs.toggle-pane
            # nur.repos.Vortriz.yaziPlugins.file-extra-metadata
            # nur.repos.xyenon.yaziPlugins.yazi-rs.jump-to-char
            # nur.repos.xyenon.yaziPlugins.yazi-rs.smart-filter
            ;

          # inputs'.nixpkgs-pkgs-update.legacyPackages.yaziPlugins.jjui;
        };
        keymap = {
          mgr.prepend_keymap = [
            {
              on = [
                "c"
                "m"
              ];
              run = "plugin chmod";
              desc = "Chmod on selected files";
            }
            {
              on = [
                "g"
                "j"
              ];
              run = "plugin jjui";
              desc = "run jjui";
            }
            {
              on = [
                "g"
                "l"
              ];
              run = "plugin lazygit";
              desc = "run lazygit";
            }
          ];
        };
      };
    };
}
