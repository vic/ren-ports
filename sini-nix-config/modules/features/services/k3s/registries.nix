# k3s registries.yaml rendered at activation from the shared registry-password age secret.
# Each container-registries emission contributes a configs.<domain>.auth entry. The cleartext
# password cannot live in the nix store, so the k3s-registries-config oneshot substitutes it
# (secret rekeyed identically on the registry host).
{ lib, ... }:
{
  ren.aspects.svc-k3s.nixos =
    { container-registries, config, ... }:
    let
      # Explicit indentation so each block nests under `configs:`. A Nix indented string (''...'')
      # strips the common leading whitespace, which would drop the `"<domain>":` key to column 0,
      # a sibling of `configs:`, so containerd reads an empty `configs` and pulls fail with
      # "no basic auth credentials". Regular strings preserve the indent.
      configsBlock = lib.concatStringsSep "\n" (
        map (
          reg:
          lib.concatStringsSep "\n" [
            "  \"${reg.domain}\":"
            "    auth:"
            "      username: \"${reg.username}\""
            "      password: \"$registry_password\""
          ]
        ) container-registries
      );
    in
    {
      systemd.services.k3s-registries-config = lib.mkIf (container-registries != [ ]) {
        description = "Render k3s registries.yaml with registry credentials";
        before = [ "k3s.service" ];
        requiredBy = [ "k3s.service" ];
        after = [ "run-agenix.d.mount" ];
        unitConfig.ConditionPathExists = config.age.secrets.registry-password.path;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          registry_password="$(cat ${config.age.secrets.registry-password.path})"
          install -d -m 0755 /etc/rancher/k3s
          umask 077
          cat > /etc/rancher/k3s/registries.yaml <<EOF
          configs:
          ${configsBlock}
          EOF
        '';
      };
    };
}
