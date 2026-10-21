{ ren, ... }:
{
  ren.aspects.dev-gui = {
    includes = with ren.aspects; [
      dev-editor-codium-antigravity
      dev-editor-codium-vscode
      dev-editor-codium-core
      dev-lang-c
      dev-lang-go
      dev-lang-lua
      dev-lang-markdown
      dev-lang-nix
      dev-lang-python
      dev-lang-shell
      dev-git-gitkraken
      dev-networking-wireshark
      dev-k8s-core
      dev-k8s-dev
      dev-k8s-helm
      dev-k8s-observability
      dev-k8s-plugins
      dev-k8s-security
      dev-k8s-tui
      dev-k8s-utils
    ];
  };
}
