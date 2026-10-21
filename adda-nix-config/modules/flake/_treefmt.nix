# treefmt: the treefmt-nix evaluation of one system, shared by the formatter and the generated files' formatter.
{ inputs }:
system:
inputs.omniflake.unified.treefmt-nix.lib.evalModule system.legacyPackages {
  imports = [ inputs.omniflake.unified.pedantix.treefmtModules.default ];

  # The patched pedantix is reached through `self`, lazily: it is a flake package (dev lane), not a treefmt default.
  # Upstream pedantix refuses every file using `|>`/`<|`; this one carries the patch that teaches its parser
  # the pipe operators (see the languages-nix aspect).
  programs.pedantix.package = inputs.self.packages.${system.name}.pedantix;

  # Used to find the project root
  # projectRootFile = "flake.nix";
  projectRootFile = ".git/config";
  enableDefaultExcludes = true;

  programs.nixfmt = {
    # projectRootFile = "flake.nix";
    enable = true;
    includes = [ "**/*.nix" ];
  };
  # settings.formatter.nixfmt.options = [ ];
  programs.deadnix.enable = true;
  programs.statix.enable = true;

  programs.pedantix.enable = true;

  programs.shellcheck.enable = true;

  programs.ruff = {
    check = true;
    format = true;
  };
  settings.formatter.ruff-check.priority = 1;
  settings.formatter.ruff-format.priority = 2;

  programs.taplo.enable = true;

  programs.toml-sort.enable = true;

  programs.mdformat.enable = true;

  settings = {
    on-unmatched = "warn";
    global.excludes = [
      "**/.gitkeep"
      # ".leaderrc"
      # "*.el" # TODO contribute an emacs treefmt
      # "*/config/nvim/*"
      # "*/config/ghostty/*"
      # "*/config/wezterm/*"
      # "*/vic/dots/ssh/*"
      # "*/vic/secrets/*"
      "**/*.atrb"
      "**/*.key"
      "**/*.crt"
      "**/*.gitignore"
      "**/*.gitmodules"
      "**/LICENSE"
      "**/.direnv"
      "**/node_modules/*"
      "node_modules/*"
      "**/*.code-workspace"
      "*.code-workspace"
    ];

    # settings.formatter.just = {
    #   # command = lib'.getExeName pkgs.just;
    #   command = "just";
    #   options = [ "--fmt" ];
    #   includes = [
    #     ".?justfile"
    #     "*.just"
    #   ];
    # };
  };
}
