# qBittorrent.conf seeder init container. Idempotent: fresh /config -> write minimal [Application] +
# [Preferences]; existing -> reconcile the keys. Disables WebUI LocalHostAuth (so the pod-loopback
# port-sync/exporter need no password) and host-header validation (proxied Host from the gateway).
# printf (not a heredoc) to survive Nix indented-string dedenting. Runs the qbt image so /config
# ownership stays consistent.
{ ... }:
{
  ren.aspects.k8s-media-qbittorrent.k8s-manifests =
    { images, ... }:
    {
      applications.qbittorrent.helm.releases.qbittorrent.values.controllers.main.initContainers.config-seed = {
        image = {
          inherit (images."linuxserver/qbittorrent") repository digest;
        };
        command = [
          "/bin/sh"
          "-c"
          ''
            set -eu
            INI=/config/qBittorrent/qBittorrent.conf
            mkdir -p /config/qBittorrent
            # A fresh pod can never legitimately hold the single-instance lock (RWO
            # PVC, replicas=1). A stale lockfile from a prior pod makes qbt assume a
            # running instance and exit 0 silently — crash-looping with zero output.
            rm -f /config/qBittorrent/lockfile
            ensure_key() {
              # ensure_key <key-escaped-for-sed> <full-line>
              # NB: $line lands in sed REPLACEMENT/append contexts, where a lone
              # backslash is consumed (s|..|WebUI\X| emits WebUIX — this is what
              # flattened the first deployment's keys on its second boot). Escape
              # backslashes for those contexts.
              key="$1"; line="$2"
              escline=$(printf '%s' "$line" | sed 's|\\|\\\\|g')
              if grep -q "^$key=" "$INI"; then
                sed -i "s|^$key=.*|$escline|" "$INI"
              else
                sed -i "/^\[Preferences\]/a $escline" "$INI"
              fi
            }
            # Same as ensure_key but for the [Application] section (FileLogger\*
            # rotation keys live there, not under [Preferences]). Creates the
            # section if absent. Idempotent.
            ensure_app_key() {
              key="$1"; line="$2"
              escline=$(printf '%s' "$line" | sed 's|\\|\\\\|g')
              grep -q '^\[Application\]' "$INI" || printf '\n[Application]\n' >> "$INI"
              if grep -q "^$key=" "$INI"; then
                sed -i "s|^$key=.*|$escline|" "$INI"
              else
                sed -i "/^\[Application\]/a $escline" "$INI"
              fi
            }
            if [ ! -f "$INI" ]; then
              echo "seeding fresh $INI"
              {
                printf '%s\n' '[Application]'
                # Bound /config/qBittorrent/logs: rotate at MaxSizeBytes keeping a
                # bounded backup set; DeleteOld prunes the oldest. The file-tail
                # sidecar ships entries before they roll off.
                printf '%s\n' 'FileLogger\Backup=true'
                printf '%s\n' 'FileLogger\DeleteOld=true'
                printf '%s\n' 'FileLogger\MaxSizeBytes=1048576'
                printf '%s\n' 'FileLogger\Age=1'
                printf '%s\n' 'FileLogger\AgeType=1'
                printf '\n'
                printf '%s\n' '[Preferences]'
                printf '%s\n' 'WebUI\LocalHostAuth=false'
                printf '%s\n' 'WebUI\HostHeaderValidation=false'
              } > "$INI"
            else
              echo "reconciling existing $INI"
              grep -q '^\[Preferences\]' "$INI" || printf '[Preferences]\n' >> "$INI"
              ensure_key 'WebUI\\LocalHostAuth' 'WebUI\LocalHostAuth=false'
              # drop flattened leftovers from the earlier whitelist attempt
              sed -i '/^WebUIAuthSubnetWhitelist/d; /^WebUIHostHeaderValidation/d' "$INI"
              ensure_key 'WebUI\\HostHeaderValidation' 'WebUI\HostHeaderValidation=false'
              # Bound the file logger (see fresh-seed comment above).
              ensure_app_key 'FileLogger\\Backup' 'FileLogger\Backup=true'
              ensure_app_key 'FileLogger\\DeleteOld' 'FileLogger\DeleteOld=true'
              ensure_app_key 'FileLogger\\MaxSizeBytes' 'FileLogger\MaxSizeBytes=1048576'
            fi
          ''
        ];
      };
    };
}
