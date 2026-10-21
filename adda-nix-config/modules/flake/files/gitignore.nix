# gitignore: the generated .gitignore (github/gitignore templates plus this repo's extras).
{ ren, inputs, ... }:
{
  ren.aspects.files-gitignore = {
    at = ren.system.x86_64-linux;
    flake-inputs =
      { ... }:
      {
        github-gitignore = {
          url = "github:github/gitignore";
          flake = false;
        };
      };
    files =
      { config, pkgs, ... }:
      {
        files.file.".gitignore" = {
          format = config.files.warning.format;
          # `gitignore-repo` is not an omniflake index name, so plain `unified` would
          # fall back to ignoreBoy's own older lock of github/gitignore and silently
          # change the generated .gitignore. Override it with the pin tracked here.
          source =
            (inputs.omniflake.lib.unifyAll { gitignore-repo = inputs.github-gitignore; })
            .ignoreboy.lib.${pkgs.stdenv.hostPlatform.system}.generateGitIgnore
              {
                # https://github.com/github/gitignore
                # - use this repo, and add the filename and/ or path/filename to the array, drop the extension. Note the
                #  uppercase filenames.
                github.languages = [
                  # "community/JavaScript/Vue"
                  "Nix"
                ];

                # `curl -sL https://www.toptal.com/developers/gitignore/api/list`
                # - this will give you a list of supported languages.
                # https://www.toptal.com/developers/gitignore/
                gitignoreio.languages = [
                  # "node"
                ];

                # GOTCHA: This will fail on first run, you will need to copy the hash into
                #    the attribute. **Everytime** you update the `gitignoreio.languages`, delete
                #    the hash, re-run the shell, and copy the updated hash back into the
                #    attribute after the next fail again. This will force the input to refresh,
                #    and make a new API request. Otherwise it will remain cached.
                # gitignoreio.hash = "";

                # Defaults to `true`, but you can set to false if you don't want OS related
                #    ignores. You don't usually need to specify. It's here for clarity.
                # useSaneDefaults = true;

                # Anything custom you might want in your .gitignore you can place in this
                #    extraConfig.
                extraConfig = ''
                  *.qcow2?
                  #  .editorconfig
                  #  .pre-commit-config.yaml
                  .devenv/

                  # Terraform (terraform/tailscale) — state/plugins/vars, never the lock file.
                  **/.terraform/
                  *.tfstate
                  *.tfstate.*
                  *.tfvars
                  *.tfvars.json
                  crash.log

                  .workspaces/
                  .old/
                '';
              };
        };
      };
  };
}
