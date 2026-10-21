# readme fragments: header, automatic-import, files, disallow-warnings (explicit order replaces dag; Q9).
# Assembly + README.md file live in channels/flake-nz.nix (readme channel) and platforms/files.nix.
{ ren, ... }:
let
  inherit (ren.helpers) repo;
  slug = "${repo.owner}/${repo.name}";
in
{
  ren.aspects.docs-readme-header = {
    at = ren.fleet.sini;
    readme = {
      order = 10;
      text = ''
        <br>

        # ${slug}

        <br>
        <div align="center">
            <a href="https://github.com/${slug}/stargazers">
                <img src="https://img.shields.io/github/stars/${slug}?color=c14d26&labelColor=0b0b0b&style=for-the-badge&logo=starship&logoColor=c14d26">
            </a>
            <a href="https://github.com/${slug}">
                <img src="https://img.shields.io/github/repo-size/${slug}?color=c14d26&labelColor=0b0b0b&style=for-the-badge&logo=github&logoColor=c14d26">
            </a>
            <a href="https://nixos.org">
                <img src="https://img.shields.io/badge/NixOS-unstable-blue.svg?style=for-the-badge&labelColor=0b0b0b&logo=NixOS&logoColor=c14d26&color=c14d26">
            </a>
            <a href="https://github.com/${slug}/blob/main/LICENSE">
                <img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&colorA=0b0b0b&colorB=c14d26&logo=unlicense&logoColor=c14d26"/>
            </a>
        </div>
        <br>

        sini's [NixOS](https://nix.dev) homelab and workstation configuration repository.

        > [!NOTE]
        > If you have any questions or suggestions, feel free to contact me via e-mail `jason <at> json64 <dot> dev`.
      '';
    };
  };

  ren.aspects.docs-readme-automatic-import = {
    at = ren.fleet.sini;
    readme = {
      order = 40;
      text = ''
        ## Automatic import

        Nix files (they're all flake-parts modules) are automatically imported.
        Nix files prefixed with an underscore are ignored.
        No literal path imports are used.
        This means files can be moved around and nested in directories freely.

        > [!NOTE]
        > This pattern has been the inspiration of [an auto-imports library, import-tree](https://github.com/vic/import-tree).

      '';
    };
  };

  ren.aspects.docs-readme-files = {
    at = ren.fleet.sini;
    readme = {
      order = 50;
      text = ''
        ## Generated files

        The following files in this repository are generated and checked
        using [the ENHANCED _files_ flake-parts module](https://github.com/sini/files):

        - `.gitignore`
        - `LICENSE`
        - `README.md`
        - `.sops.yaml`
        - `.secrets/secrets-manifest.md`
      '';
    };
  };

  ren.aspects.docs-readme-disallow-warnings = {
    at = ren.fleet.sini;
    readme = {
      order = 60;
      text = ''
        ## Trying to disallow warnings

        This at the top level of the `flake.nix` file:

        ```nix
        nixConfig.abort-on-warn = true;
        ```

        > [!NOTE]
        > It does not currently catch all warnings Nix can produce, but perhaps only evaluation warnings.
      '';
    };
  };
}
