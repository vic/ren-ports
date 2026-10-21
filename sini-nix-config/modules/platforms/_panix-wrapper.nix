# panix wrapper: runs panix from <repo root>/.panix (0700) on a copy of panix-config with the flake url filled in.
{ pkgs, lib, panix-config, urlSentinel, panix }:
pkgs.writeShellApplication {
  name = "panix";
  runtimeInputs = [ pkgs.git ];
  text = ''
    root=''${PRJ_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || true)}
    if [ -z "$root" ]; then
      echo "panix: run from the devshell or inside the flake's git checkout" >&2
      exit 1
    fi
    state="$root/.panix"
    if [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
      tmp="$XDG_RUNTIME_DIR/panix"
    else
      tmp="$state/tmp"
    fi
    umask 077
    mkdir -p "$state" "$tmp"
    chmod 0700 "$state" "$tmp"
    if [ -n "''${PANIX_CONFIG:-}" ]; then
      PANIX_CONFIG=$(realpath "$PANIX_CONFIG")
    else
      sed 's|${urlSentinel}|git+file://'"$root"'|g' ${panix-config} > "$state/panix.yml"
      PANIX_CONFIG="$state/panix.yml"
    fi
    export PANIX_CONFIG
    export TMPDIR="$tmp"
    cd "$state"
    exec ${lib.getExe panix} "$@"
  '';
}
