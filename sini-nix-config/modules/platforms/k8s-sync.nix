# nixidy battery flake outputs: nixidy-all-envs, nixidy-sync, post-process idempotency check, devshell env.
# Per-system packages/checks classes (platforms/outputs.nix) at system scope.
# Env names are read from inputs.self.nixidyEnvs.<system> (as den: flake-level, not the per-system pkgs, so no
# package-set self reference); `system` is the system-scope binding (README:177).
{ ren, lib, inputs, ... }:
let
  envsOf = system: inputs.self.nixidyEnvs.${system.name} or { };
in
{
  ren.aspects.nixidy-sync = {
    at = ren.kinds.system;
    packages =
      { pkgs, system, ... }:
      {
        nixidy-sync = pkgs.writeShellApplication {
          name = "nixidy-sync";
          runtimeInputs = [ pkgs.git pkgs.nix ];
          # only env NAMES are baked; each activationPackage is built at run time against the current tree
          text = ''
            if [ "''${1:-}" = "--skip-secrets" ] || [ "''${1:-}" = "-s" ]; then
              export NIXIDY_SKIP_POST_PROCESS=1
            fi
            root="$(git rev-parse --show-toplevel)" || { echo "nixidy-sync: not in a git repo" >&2; exit 1; }
            cd "$root"
            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (env: _: ''
                echo "==> Syncing nixidy env: ${env}"
                out="$(nix build --no-link --print-out-paths ".#nixidyEnvs.${system.name}.${env}.activationPackage")"
                "$out"/activate
              '') (envsOf system)
            )}
          '';
        };
        # every env's manifests linked together with a manifest.json index
        nixidy-all-envs =
          let
            envData = lib.mapAttrs (_: e: {
              inherit (e.config.nixidy.target) repository branch rootPath;
              package = e.environmentPackage;
            }) (envsOf system);
          in
          pkgs.runCommand "nixidy-all-envs" { } ''
            mkdir -p $out
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (env: d: "ln -s ${d.package} $out/${env}") envData)}
            cat > $out/manifest.json <<'MANIFEST'
            ${builtins.toJSON (
              lib.mapAttrs (_: d: {
                inherit (d) repository branch rootPath;
                packagePath = "${d.package}";
              }) envData
            )}
            MANIFEST
          '';
      };
    devshell.env = [
      {
        name = "NIXIDY_POST_PROCESS_APPROVE";
        value = "1";
      }
    ];
    # the SHARED SopsSecret post-process command run with stubbed vals/sops (hermetic, no yubikey/network)
    checks =
      { pkgs, ... }:
      {
        drvs.secret-post-process-idempotency =
          let
            postProcessCommand = import ../features/k8s/nixidy/_secret-post-process-command.nix;
          in
          pkgs.runCommand "secret-post-process-idempotency"
            {
              nativeBuildInputs = [
                pkgs.yq-go
                pkgs.coreutils
              ];
            }
            ''
              set -euo pipefail
              export HOME="$PWD"
              mkdir -p stub-bin
              printf '#!/bin/sh\ncat\n' > stub-bin/vals
              printf '#!/bin/sh\nprintf "SOPS-ENC["\ncat /dev/stdin\nprintf "]"\n' > stub-bin/sops
              chmod +x stub-bin/*
              export PATH="$PWD/stub-bin:$PATH"
              : > .sops.yaml
              cat > post-process.sh <<'POST_PROCESS_EOF'
              ${postProcessCommand}
              POST_PROCESS_EOF
              fail() { echo "FAIL: $1" >&2; exit 1; }
              PLAINTEXT='apiVersion: isindir.github.com/v1alpha3
              kind: SopsSecret
              metadata:
                name: demo
                annotations: {}
              stringData:
                password: hunter2'
              SHA="$(printf '%s' "$PLAINTEXT" | sha256sum | cut -d' ' -f1)"
              # 1: matching hash -> byte-identical, no re-encrypt
              TARGET="$PWD/target.yaml"
              printf '%s' "$PLAINTEXT" \
                | yq '.metadata.annotations."secrets.json64.dev/plaintext-sha256" = "'"$SHA"'"' > "$TARGET"
              EXPECTED="$(cat "$TARGET")"
              OUT1="$(printf '%s' "$PLAINTEXT" | TARGET_PATH="$TARGET" sh post-process.sh)"
              [ "$OUT1" = "$EXPECTED" ] || fail "case1: expected byte-identical target, got re-encrypt"
              # 2: mutated plaintext -> re-encrypt with the new hash
              MUTATED="''${PLAINTEXT/hunter2/changed-password}"
              NEWSHA="$(printf '%s' "$MUTATED" | sha256sum | cut -d' ' -f1)"
              OUT2="$(printf '%s' "$MUTATED" | TARGET_PATH="$TARGET" sh post-process.sh)"
              case "$OUT2" in SOPS-ENC*) : ;; *) fail "case2: expected re-encrypted output" ;; esac
              [[ "$OUT2" == *"$NEWSHA"* ]] || fail "case2: re-encrypted body missing new hash"
              # 3: unreadable annotation -> fail-closed re-encrypt
              ENC_TARGET="$PWD/enc-target.yaml"
              printf 'fully: encrypted\n' > "$ENC_TARGET"
              OUT3="$(printf '%s' "$PLAINTEXT" | TARGET_PATH="$ENC_TARGET" sh post-process.sh)"
              case "$OUT3" in SOPS-ENC*) : ;; *) fail "case3: expected fail-closed re-encrypt" ;; esac
              touch "$out"
            '';
      };
  };
}
