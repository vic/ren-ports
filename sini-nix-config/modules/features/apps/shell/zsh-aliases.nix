{ ... }:
{
  ren.aspects.app-shell-zsh.homeManager = {
    programs.zsh.shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      "rm" = "rm -i";
      "j" = "journalctl -xe";
      "e" = "emacsclient -n";
      "start" = "systemctl --user start";
      "stop" = "systemctl --user stop";
      "enable" = "systemctl --user enable";
      "disable" = "systemctl --user disable";
      "reload" = "systemctl --user daemon-reload";
      "status" = "systemctl --user --full status";
      "restart" = "systemctl --user restart";
      "ssh-kitty" = "kitty +kitten ssh";
      "ssh-ignore" =
        "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null";
      "fixstore" = "sudo nix-store --verify --check-contents --repair";
      "flake-update" = "nix flake update --option access-tokens \"github.com=$(gh auth token)\"";
    };
  };
}
