# hindsight secrets. The single generator for each bank's token; the .age files
# are created by `agenix generate`. Rekey targets of the same rekeyFile, with no
# generator of their own: this pod (via sops), the genie token at
# services.ai.genie-bank-review (sini@bitstream), the genie-memory token at
# services.ai.genie-memory-loader (sini@cortex), and the den-law token at
# applications.dev.ai.mcp.hindsight (sini on every host with the hindsight
# client), and each reader token at that aspect for its reader.
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
  shared = import ./_hindsight/shared.nix { inherit lib; };
in
{
  ren.aspects.k8s-ai-hindsight.age-secrets =
    { environment, ... }:
    {
      imports = [
        ({ config, ... }: {
      age.secrets =
        lib.listToAttrs (
          map (
            bank:
            lib.nameValuePair (shared.tokenSecret bank) {
              rekeyFile = environment.secretPath + "/hindsight/${shared.tokenName bank}.age";
              generator.script = "hex";
              sopsOutput = {
                file = "hindsight";
                key = shared.tokenName bank;
              };
            }
          ) shared.gatedBankNames
        )
        # Each reader's token, rekeyed to that reader by the hindsight client aspect.
        // lib.listToAttrs (
          map (
            t:
            lib.nameValuePair "hindsight-${t.name}" {
              rekeyFile = environment.secretPath + "/hindsight/${t.name}.age";
              generator.script = "hex";
              sopsOutput = {
                file = "hindsight";
                key = t.name;
              };
            }
          ) shared.readerTokens
        )
        // {
          # The control plane's admin token: a sops target of the CP pod only.
          # No trailing newline, because the CP sends the value verbatim in its
          # Authorization header.
          hindsight-cp-admin-token = {
            rekeyFile = environment.secretPath + "/hindsight/cp-admin-token.age";
            # Fails rather than emit anything but 64 hex digits.
            generator.script =
              { pkgs, ... }:
              "t=$(${pkgs.openssl}/bin/openssl rand -hex 32) && [ \"\${#t}\" -eq 64 ] && printf '%s' \"$t\"";
            sopsOutput = {
              file = "hindsight";
              key = "cp-admin-token";
            };
          };
          # Its SHA-256, derived from it, which is all the dataplane holds.
          hindsight-cp-admin-token-sha256 = {
            rekeyFile = environment.secretPath + "/hindsight/cp-admin-token-sha256.age";
            generator = {
              dependencies = [ config.age.secrets.hindsight-cp-admin-token ];
              script =
                {
                  decrypt,
                  deps,
                  pkgs,
                  ...
                }:
                "${decrypt} ${lib.escapeShellArg (lib.head deps).file} | ${pkgs.coreutils}/bin/tr -d '\\n' | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d' ' -f1 | ${pkgs.coreutils}/bin/tr -d '\\n'";
            };
            sopsOutput = {
              file = "hindsight";
              key = "cp-admin-token-sha256";
            };
          };
          # The gateway's OIDC client secret; kanidm.nix declares the same
          # rekeyFile and generator for the `hindsight` client.
          hindsight-oidc-client-secret = {
            rekeyFile = environment.secretPath + "/oidc/hindsight-oidc-client-secret.age";
            generator = {
              tags = [ "oidc" ];
              script = "rfc3986-secret";
            };
            sopsOutput = {
              file = "oidc";
              key = "hindsight";
            };
          };
        };
        })
      ];
    };
}
