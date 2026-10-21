# second file of dev-editor-codium-core: codium-settings (attrs fold, was a one-element list in den).
{ ... }:
{
  ren.aspects.dev-editor-codium-core.codium-settings = {
    "catppuccin-icons.hidesExplorerArrows" = false;
    "catppuccin-icons.specificFolders" = true;
    "catppuccin-icons.monochrome" = false;
    "chat.mcp.autostart" = "newAndOutdated";
    "chat.mcp.discovery.enabled" = {
      "claude-desktop" = true;
      "cursor-global" = true;
      "cursor-workspace" = true;
      "windsurf" = true;
    };
    "claudeCode.preferredLocation" = "panel";
    "cSpell.userWords" = [
      "distro"
      "distrobox"
      "distroboxrc"
      "distros"
      "dkms"
      "Flatpak"
      "gphoto"
      "Keyer"
      "libnvidia"
      "localuser"
      "NVENC"
      "Pango"
      "Pipewire"
      "Quickemu"
      "quickget"
      "quickreport"
      "reqwest"
      "RIST"
      "RTMP"
      "RTSP"
      "shellcheck"
      "Syncthing"
      "ublue"
      "Vulkan"
      "Wimpress"
      "xhost"
      "Xwayland"
    ];
    "direnv.restart.automatic" = true;
    "editor.bracketPairColorization.independentColorPoolPerBracketType" = true;
    "editor.fontLigatures" = true;
    "editor.fontWeight" = "400";
    "editor.guides.bracketPairs" = true;
    "editor.guides.bracketPairsHorizontal" = true;
    "editor.inlineSuggest.enabled" = true;
    "editor.renderWhitespace" = "all";
    "editor.rulers" = [
      80
      120
    ];
    "editor.semanticHighlighting.enabled" = true;
    "explorer.confirmDragAndDrop" = false;
    "extensions.autoCheckUpdates" = false;
    "extensions.ignoreRecommendations" = true;
    "[xml]"."editor.defaultFormatter" = "DotJoshJohnson.xml";
    "files.insertFinalNewline" = true;
    "files.trimTrailingWhitespace" = true;
    "git.openRepositoryInParentFolders" = "always";
    "github.copilot.chat.agent.thinkingTool" = true;
    "github.copilot.chat.codesearch.enabled" = true;
    "githubPullRequests.pullBranch" = "never";
    "partialDiff.enableTelemetry" = false;
    "projectManager.git" = {
      baseFolders = [
        "~/repos"
      ];
      maxDepthRecursion = 5;
    };
    "redhat.telemetry.enabled" = false;
    "security.workspace.trust.untrustedFiles" = "open";
    "telemetry.feedback.enabled" = false;
    "telemetry.telemetryLevel" = "off";
    "terminal.integrated.scrollback" = 10240;
    "terminal.integrated.copyOnSelection" = true;
    "terminal.integrated.cursorBlinking" = true;
    "update.mode" = "none";
    "vsicons.dontShowNewVersionMessage" = true;
    "workbench.tree.indent" = 20;
    "workbench.startupEditor" = "none";
    "workbench.editor.empty.hint" = "hidden";
  };
}
