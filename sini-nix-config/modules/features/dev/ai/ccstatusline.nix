# ccstatusline (github:sirmalloc/ccstatusline): the Claude Code status line, taken
# from the numtide collection we already ship as an input rather than from npx at
# runtime. The binary, the config and the Claude Code wiring all live here.
# Layout (the two lines) is in _ccstatusline/lines.nix.
#
# THE CONFIG IS A READ-ONLY STORE SYMLINK, like ~/.claude/settings.json. Its own
# TUI (`ccstatusline` with no args) is still the right way to BROWSE widgets and
# preview colours, but its save will fail — change the layout HERE, not in the TUI.
# On save the TUI ALSO rewrites ~/.claude/settings.json to sync widget hooks, and
# that file is generated too.
{ inputs, ... }:
{
  ren.aspects.dev-ai-tools-ccstatusline.homeManager =
    { lib, pkgs, ... }:
    let
      ccstatusline = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.ccstatusline;

      settings = {
        # Must equal the binary's CURRENT_VERSION. On a lower number ccstatusline
        # migrates the config and WRITES THE RESULT BACK — into the store symlink's
        # target, which is read-only, so the write throws, the whole load is
        # abandoned and the bar renders "⚠ invalid config" off the defaults. A
        # generated config has to arrive pre-migrated; bump this and the shape
        # below together whenever the ccstatusline input moves.
        version = 4;

        lines = import ./_ccstatusline/lines.nix lib;

        flexMode = "full-minus-40";
        compactThreshold = 60;
        colorLevel = 2;
        defaultPadding = " ";
        inheritSeparatorColors = false;
        globalBold = false;
        gitCacheTtlSeconds = 5;
        minimalistMode = false;

        # Off on purpose: powerline separators are private-use codepoints that
        # render as tofu without a patched font, and the fallback is silent.
        powerline = {
          enabled = false;
          separators = [ "" ];
          separatorInvertBackground = [ false ];
          startCaps = [ ];
          endCaps = [ ];
          autoAlign = false;
          continueThemeAcrossLines = false;
        };
      };
    in
    {
      home.packages = [ ccstatusline ];

      # home.file, not xdg.configFile: ccstatusline joins homedir + ".config"
      # directly and never consults XDG_CONFIG_HOME, so this is the path it reads.
      home.file.".config/ccstatusline/settings.json".source =
        (pkgs.formats.json { }).generate "ccstatusline-settings.json"
          settings;

      programs.claude-code.settings.statusLine = {
        type = "command";
        command = lib.getExe ccstatusline;
        padding = 0;
      };
    };
}
