# treefmt programs (second file of flake-treefmt).
{ ... }:
{
  ren.aspects.flake-treefmt.treefmt =
    { system, ... }:
    {
      programs = {
        actionlint.enable = true;
        fish_indent.enable = true;
        isort.enable = true;
        nixfmt = {
          enable = true;
          package = system.legacyPackages.nixfmt;
          includes = [ "**/*.nix" ];
        };
        nixf-diagnose = {
          enable = true;
          ignore = [
            "sema-unused-def-lambda-witharg-formal"
            "sema-unused-def-lambda-noarg-formal"
            "sema-primop-overridden"
            "sema-unused-def-let"
          ];
        };
        prettier = {
          enable = true;
          settings = {
            arrowParens = "always";
            bracketSameLine = false;
            bracketSpacing = true;
            editorconfig = true;
            embeddedLanguageFormatting = "auto";
            endOfLine = "lf";
            htmlWhitespaceSensitivity = "css";
            insertPragma = false;
            jsxSingleQuote = true;
            printWidth = 80;
            proseWrap = "always";
            quoteProps = "consistent";
            requirePragma = false;
            semi = true;
            singleAttributePerLine = true;
            singleQuote = false;
            trailingComma = "all";
            useTabs = false;
            vueIndentScriptAndStyle = false;
            tabWidth = 2;
          };
        };
        ruff = {
          check = true;
          format = true;
        };
        taplo.enable = true;
        yamlfmt.enable = true;
        toml-sort.enable = true;
        shellcheck.enable = true;
      };
    };
}
