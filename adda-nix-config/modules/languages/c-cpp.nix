# c-cpp: C/C++ toolchain and editor wiring.
{ ren, ... }:
{
  ren.aspects.languages-c-cpp = {
    zed-extensions = { ... }: [ "neocmake" ];

    zedPackages =
      { pkgs, ... }:
      with pkgs;
      [
        clang-tools
      ];

    helixLanguages = {
      language = [
        {
          name = "cpp";
          language-servers = [
            "clangd"
          ];
          auto-format = false;
        }
        {
          name = "c";
          language-servers = [
            "clangd"
          ];
          auto-format = false;
        }
      ];
    };

    vscodiumSettings = {
      cmake = {
        configureOnOpen = false;
        showOptionsMovedNotification = false;
        pinnedCommands = [
          "workbench.action.tasks.configureTaskRunner"
          "workbench.action.tasks.runTask"
        ];
      };
      C_Cpp = {
        vcFormat = {
          newLine.beforeOpenBrace = {
            namespace = "sameLine";
            type = "sameLine";
            lambda = "sameLine";
            function = "sameLine";
            block = "sameLine";
          };
          space = {
            beforeConstructorColon = false;
            beforeInheritanceColon = false;
          };
        };
        formatting = "vcFormat";
      };
    };

    vscodium-extensions =
      { ... }:
      [
        "ms-vscode.cmake-tools"
        "ms-vscode.cpptools-extension-pack"
        "llvm-vs-code-extensions.vscode-clangd"
      ];

    # The toolchain itself. Editors above only wire binaries up; without these the
    #  aspect is silent on a machine that builds nothing in a per-project devshell —
    #  which is exactly the headless-server case.
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          clang # Compiler, driver (`clang`, `clang++`).
          clang-tools # clangd, clang-tidy, clang-format.
          cmake
          gnumake
          pkg-config
          gdb
        ];
      };
  };
}
