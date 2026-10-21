# envrc: the generated .envrc (direnv loads the flake's default devshell).
{ ren, ... }:
{
  ren.aspects.files-envrc = {
    at = ren.system.x86_64-linux;
    files =
      { config, ... }:
      {
        files.file.".envrc" = {
          text = ''
            #!/usr/bin/env sh
            # shellcheck shell=bash

            ${config.files.warning.formatters.envrc config.files.warning.text}
            use flake .

            dotenv_if_exists .env.private
            source_env_if_exists .envrc.private
          '';
        };
      };
  };
}
