# files: the `files` class writes repo files with sini/files (`nix run .#write-files`); `.warning` prepends the DO-NOT-EDIT notice.
{ ren, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  treefmt = import ../_treefmt.nix { inherit inputs; };
  extensionOf =
    name:
    let
      parts = lib.splitString "." name;
    in
    if builtins.length parts > 1 then lib.last parts else "";

  # `files.warning.*`: the generated-file notice and the per-file `format` functions built on it
  warning =
    system:
    { config, pkgs, ... }:
    let
      cfg = config.files;
    in
    {
      options.files.warning = {
        text = lib.mkOption {
          type = lib.types.str;
          description = "Text to include in the generated comment at the top of generated files.";
          default = ''
            DO-NOT-EDIT.
            This file was auto-generated using github:sini/files.
            Use `nix run .#write-files` to regenerate it.
          '';
        };
        formatters = lib.mkOption {
          type = lib.types.attrsOf (lib.types.functionTo lib.types.str);
          description = "Functions to format comments for different file types.";
          default =
            let
              hashSign =
                text:
                lib.concatMapStringsSep "\n" (line: if line == "" then "" else "# ${line}") (
                  lib.splitString "\n" text
                );
            in
            {
              md = text: "<!-- ${text} -->\n";
              sh = hashSign;
              envrc = hashSign;
              gitignore = hashSign;
              nix = hashSign;
              toml = hashSign;
              license = _: "";
            };
          readOnly = true;
        };
        # No file type needed for the common case: it's inferred from the file's own name (".gitignore" -> "gitignore",
        #  "README.md" -> "md", ...).
        # Only files whose name doesn't carry its own type (e.g. ".intellishell") need `formatAs "sh"` instead.
        format = lib.mkOption {
          type = lib.types.functionTo (lib.types.functionTo lib.types.package);
          readOnly = true;
          description = ''
            `files.file.<name>.format` function that prepends the generated-warning comment
            (inferring the comment style from `name`'s own extension) and reformats via
            treefmt. Leave a file's `format` unset to skip the warning entirely.
          '';
        };
        formatAs = lib.mkOption {
          type = lib.types.functionTo (lib.types.functionTo (lib.types.functionTo lib.types.package));
          readOnly = true;
          description = ''
            Like `files.warning.format`, but for files whose name doesn't carry a usable
            type, e.g. `format = config.files.warning.formatAs "sh";`.
          '';
        };
      };

      config.files = {
        treefmt.enable = true;

        # `files.treefmt.enable` and `files.warning.format`/`formatAs` both invoke treefmt on
        # files that live outside the actual git worktree (they run inside the Nix sandbox), so
        # treefmt's usual upward search for `config.treefmt.projectRootFile` (`.git/config`)
        # can't find a tree root there. Point it at the file being formatted instead.
        treefmt.package = pkgs.writeShellScriptBin "treefmt-tree-root-file" ''
          exec ${lib.getExe (treefmt system).config.build.wrapper} --tree-root-file "''${@: -1}" "$@"
        '';

        warning.formatAs =
          fileType: name: drv:
          let
            mkComment = cfg.warning.formatters.${fileType} or null;
            comment = if mkComment == null then "" else mkComment cfg.warning.text;
            escapedName = lib.escapeShellArg name;
          in
          pkgs.runCommandLocal "warned-${builtins.replaceStrings [ "/" ] [ "-" ] name}" { inherit comment; }
            ''
              mkdir -p "$(dirname ${escapedName})"
              touch ${escapedName}
              if [ -n "$comment" ]; then
                echo "$comment" >> ${escapedName}
              fi
              cat ${drv} >> ${escapedName}
              ${lib.getExe cfg.treefmt.package} --no-cache ${escapedName}
              mv ${escapedName} $out
            '';

        warning.format = name: cfg.warning.formatAs (extensionOf name) name;

        generateApp = true;
      };
    };
in
{
  ren.classes.files = {
    at = ren.system.x86_64-linux;
    into =
      { system, ... }:
      ms:
      let
        e = lib.evalModules {
          specialArgs.pkgs = system.legacyPackages;
          modules = [
            inputs.omniflake.unified."github:sini/files".module
            (warning system)
            { config.files.root = inputs.self; }
          ]
          ++ ms;
        };
      in
      {
        packages.write-files = e.config.files.writer.drv; # a channel emission
        checks.${system.name} = e.config.files.checks;
      };
  };
}
