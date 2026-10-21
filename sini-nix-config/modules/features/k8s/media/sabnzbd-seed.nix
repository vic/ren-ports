# SABnzbd config-seed init container: seeds/reconciles sabnzbd.ini (api_key from media-arr-api-keys,
# host_whitelist, inet_exposure, /scratch dirs, log rotation). Idempotent; printf not heredoc so it
# survives Nix indented-string dedenting. Runs the SAB image so /config ownership stays consistent.
{ ... }:
{
  ren.aspects.k8s-media-sabnzbd.k8s-manifests =
    { images, ... }:
    {
      applications.sabnzbd.helm.releases.sabnzbd.values.controllers.main.initContainers.config-seed = {
        image = {
          inherit (images."linuxserver/sabnzbd") repository digest;
        };
        env.API_KEY.valueFrom.secretKeyRef = {
          name = "media-arr-api-keys";
          key = "sabnzbd";
        };
        command = [
          "/bin/sh"
          "-c"
          ''
          set -eu
          INI=/config/sabnzbd.ini
          WHITELIST="nzb.json64.dev, sabnzbd"
          # Bound /config/logs: SAB rotates sabnzbd.log at max_log_size bytes,
          # keeping log_backups files. 1 MiB * 2 backups keeps the dir small; the
          # file-tail sidecar ships entries before they roll off.
          LOG_SIZE="1048576"
          LOG_BACKUPS="2"
          mkdir -p /scratch/usenet/incomplete /scratch/usenet/complete
          # ensure_key <section-header-regex> <key> <full-line>: set <key> under
          # the given section (creating the section if absent). The section must be
          # the LAST one for the simple `/<section>/a` append to land inside it; we
          # only use it for [logging] which we append at end-of-file below.
          ensure_logging_key() {
            key="$1"; line="$2"
            grep -q '^\[logging\]' "$INI" || printf '\n[logging]\n' >> "$INI"
            if grep -q "^$key = " "$INI"; then
              sed -i "s|^$key = .*|$line|" "$INI"
            else
              sed -i "/^\[logging\]/a $line" "$INI"
            fi
          }
          if [ ! -f "$INI" ]; then
            echo "seeding fresh $INI"
            {
              printf '%s\n' '[misc]'
              printf '%s\n' 'host = 0.0.0.0'
              printf '%s\n' 'port = 8080'
              printf '%s\n' "api_key = $API_KEY"
              printf '%s\n' "host_whitelist = $WHITELIST"
              printf '%s\n' 'inet_exposure = 4'
              printf '%s\n' 'download_dir = /scratch/usenet/incomplete'
              printf '%s\n' 'complete_dir = /scratch/usenet/complete'
              printf '%s\n' '[logging]'
              printf '%s\n' "max_log_size = $LOG_SIZE"
              printf '%s\n' "log_backups = $LOG_BACKUPS"
            } > "$INI"
          else
            echo "reconciling existing $INI"
            # sed "/^\[misc\]/a ..." silently no-ops if [misc] is absent (set -e can't
            # catch it), so ensure the section exists before any append below.
            grep -q '^\[misc\]' "$INI" || printf '[misc]\n' >> "$INI"
            if grep -q '^api_key = ' "$INI"; then
              sed -i "s|^api_key = .*|api_key = $API_KEY|" "$INI"
            else
              sed -i "/^\[misc\]/a api_key = $API_KEY" "$INI"
            fi
            if grep -q '^host_whitelist = ' "$INI"; then
              sed -i "s|^host_whitelist = .*|host_whitelist = $WHITELIST|" "$INI"
            else
              sed -i "/^\[misc\]/a host_whitelist = $WHITELIST" "$INI"
            fi
            # inet_exposure 4 = WebUI reachable from non-local clients (the gateway's
            # pod network); without it SAB answers "External internet access denied".
            if grep -q '^inet_exposure = ' "$INI"; then
              sed -i "s|^inet_exposure = .*|inet_exposure = 4|" "$INI"
            else
              sed -i "/^\[misc\]/a inet_exposure = 4" "$INI"
            fi
            ensure_logging_key 'max_log_size' "max_log_size = $LOG_SIZE"
            ensure_logging_key 'log_backups' "log_backups = $LOG_BACKUPS"
          fi
          ''
        ];
      };
    };
}
