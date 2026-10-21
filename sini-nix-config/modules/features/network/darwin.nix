# Tailscale on Darwin: enables the service and authenticates on activation,
# since nix-darwin has no declarative authKeyFile equivalent.
# den `tailscale.darwin` was tailscale's own `darwin` class key, so it applied only where tailscale is included:
# `is ren.aspects.network-tailscale mac` keeps that (README.md:559), plus the preauthkey pathExists gate.
{ ren, lib, ... }:
{
  ren.aspects.network-tailscale-darwin = {
    at = ren.kinds.mac;

    darwin =
      {
        config,
        environment,
        is,
        mac,
        pkgs,
        ...
      }:
      let
        authKeyPath = config.age.secrets.tailscale-auth-key.path;
      in
      lib.mkIf (is ren.aspects.network-tailscale mac && builtins.pathExists (mac.secretPath + "/tailscale-preauthkey.age")) {
        services.tailscale.enable = true;

        # MagicDNS parity with Linux. The open-source `tailscaled` under launchd
        # does not program the macOS resolver, and nix-darwin compensates only for
        # the default `ts.net` base domain. This fleet's headscale uses
        # `ts.${environment.domain}`: route just the tailnet zone to tailscale's
        # resolver (100.100.100.100). Public names stay on the normal resolver, so
        # DNS keeps working when the laptop roams off the tailnet.
        environment.etc."resolver/ts.${environment.domain}".text = "nameserver 100.100.100.100";

        system.activationScripts.postActivation.text = ''
          # Tailscale auto-authentication
          if [ -f "${authKeyPath}" ]; then
            echo "Configuring Tailscale..."

            # Wait for tailscaled to be ready (max 10 seconds)
            for _ in $(seq 1 10); do
              if /run/current-system/sw/bin/tailscale status &>/dev/null; then
                break
              fi
              sleep 1
            done

            current_status=$(/run/current-system/sw/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.BackendState // "Unknown"' || echo "Unknown")

            if [ "$current_status" = "Running" ]; then
              echo "Tailscale already connected"
            else
              echo "Authenticating Tailscale with hostname ${mac.name}..."
              # --reset clears any conflicting non-default settings
              /run/current-system/sw/bin/tailscale up \
                --login-server=https://${ren.helpers.domainFor environment "headscale"} \
                --auth-key="$(cat ${authKeyPath})" \
                --hostname="${mac.name}" \
                --reset \
                || echo "Tailscale auth failed (may need manual login)"
            fi

            # Accept the control plane's pushed DNS so 100.100.100.100 answers
            # MagicDNS. `up --reset` defaults this on; set it idempotently so a
            # node connected before this change also picks it up.
            /run/current-system/sw/bin/tailscale set --accept-dns=true 2>/dev/null || true
          else
            echo "Warning: Tailscale auth key not found at ${authKeyPath}"
            echo "Run: agenix generate to add tailscale-auth"
          fi

          # macOS caches resolver config in mDNSResponder, so a freshly written
          # /etc/resolver entry is ignored until the cache is flushed.
          /usr/bin/dscacheutil -flushcache 2>/dev/null || true
          /usr/bin/killall -HUP mDNSResponder 2>/dev/null || true
        '';
      };
  };
}
