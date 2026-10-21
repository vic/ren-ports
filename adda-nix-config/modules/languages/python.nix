# python: interpreter, LSP and editor wiring for Python.
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.languages-python = {
    zed-extensions = { ... }: [
      "pylsp"
      "python-snippets"
    ];

    vscodium-extensions = { ... }: [
      "ms-python.python"
      "ms-python.debugpy"
      "ms-toolsai.jupyter"
      # vscode-marketplace.harttrav.markdown-jupytext"
    ];

    # The toolchain itself. `helixLanguages` below names `ruff`/`pylsp` binaries; this
    #  is what puts them (and an interpreter) on PATH, on headless hosts too.
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          python3
          ruff # Linter + formatter; also the `ruff server` LSP below.
          python3Packages.python-lsp-server # pylsp, the second language-server below.
        ];
      };

    helixLanguages =
      { pkgs, ... }:
      let
        inherit (addax) getExeName;
      in
      {
        language = [
          {
            name = "python";
            indent = {
              tab-width = 4;
              unit = " ";
            };
            auto-format = true;
            language-servers = [
              (getExeName pkgs.ruff)
              (getExeName pkgs.python3Packages.python-lsp-server)
            ];
            formatter = {
              command = getExeName pkgs.ruff;
              args = [
                "format"
                "-" # stdin
                # "--quiet"
                # "--line-length=120"
              ];
            };
          }
        ];
        language-server = {
          pylsp = {
            config.pylsp.plugins = {
              flake8 = {
                enabled = false;
              };
              autopep8 = {
                enabled = false;
              };
              mccabe = {
                enabled = false;
              };
              pycodestyle = {
                enabled = false;
              };
              pyflakes = {
                enabled = false;
              };
              pylint = {
                enabled = false;
              };
              yapf = {
                enabled = false;
              };
              ruff = {
                enabled = false;
              };
            };
          };

          ruff = {
            command = "${getExeName pkgs.ruff}";
            args = [ "server" ];
            config = {
              settings = {
                lineLength = 120;
                lint = {
                };
                # format = {
                # preview = true;
                # };
              };
            };
          };
        };
      };
  };
}
