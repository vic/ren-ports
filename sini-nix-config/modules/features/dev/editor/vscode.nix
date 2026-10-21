{ ... }:
{
  ren.aspects.dev-editor-codium-vscode = {
    homeManager =
      {
        codium-settings,
        codium-extensions,
        lib,
        ...
      }:
      {
        programs.vscode = {
          enable = true;
          mutableExtensionsDir = false;
          profiles.default = {
            # codium-settings pool is an attrs fold (channel editors-am), already merged
            userSettings = codium-settings;
            extensions = lib.unique (lib.flatten codium-extensions);
          };
        };
      };

    persistHome = {
      directories = [
        ".config/VSCodium"
        ".config/Code"
        ".vscode"
        ".vscode-oss"
        ".vscode-shared"
      ];
    };
  };
}
