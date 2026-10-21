# shellcheck shell=bash
#
# umu-run inside a bubblewrap sandbox: no network, and no view of $HOME beyond the game's own
#  directory plus the handful of paths umu/Proton genuinely need.
#
# Why a namespace rather than a firewall rule: a Windows game runs as this user, so anything that
#  can be reached with this uid (ssh keys, gnupg/kwallet sockets, the whole synchronized/ tree) is
#  reachable by the game and by whatever it ships. The namespace removes the paths instead of
#  filtering them, and 'unshare-net' removes egress instead of trusting the game to behave.
#
# What is deliberately *not* hidden: /nix/store, /etc, /sys and /dev (read-only apart from /dev,
#  which needs to be a real bind for /dev/dri, /dev/input and /dev/shm). The wine prefix, the umu
#  runtime and the shader caches must be writable or nothing launches.

usage() {
    cat <<'EOF'
umu-jail [OPTIONS] [--] <EXE|VERB> [GAME ARGS...]

Run umu-run with no network access and a minimal filesystem view.

Options:
  -n, --net             allow network access (default: denied)
  -s, --share DIR       bind DIR read-write   (repeatable)
  -r, --ro DIR          bind DIR read-only    (repeatable)
  -p, --prefix DIR      WINEPREFIX (default: $WINEPREFIX, else ~/Games/umu/$GAMEID)
  -H, --host-home       expose the whole real $HOME (escape hatch)
  -D, --dbus            expose the session D-Bus socket (default: hidden)
  -P, --print           print the bwrap invocation instead of running it
  -h, --help            this text

Writable by default: the directory of EXE, the wine prefix,
~/.local/share/{umu,Steam/compatibilitytools.d} and the Proton/Mesa caches.
Visible read-only: /nix/store /etc /sys, a private /tmp, and the
Wayland/X11/PipeWire/PulseAudio sockets. Everything else in $HOME is gone.
EOF
}

net=0 hosthome=0 dbus=0 dryrun=0
shares=() ros=()
prefix=${WINEPREFIX:-}

while (($#)); do
    case $1 in
    -n | --net) net=1 && shift ;;
    -s | --share) shares+=("${2:?--share needs a directory}") && shift 2 ;;
    -r | --ro) ros+=("${2:?--ro needs a directory}") && shift 2 ;;
    -p | --prefix) prefix=${2:?--prefix needs a directory} && shift 2 ;;
    -H | --host-home) hosthome=1 && shift ;;
    -D | --dbus) dbus=1 && shift ;;
    -P | --print) dryrun=1 && shift ;;
    -h | --help)
        usage
        exit 0
        ;;
    --) shift && break ;;
    -*)
        echo "umu-jail: unknown option: $1" >&2
        exit 2
        ;;
    *) break ;;
    esac
done

if (($# == 0)); then
    usage >&2
    exit 2
fi

: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_RUNTIME_DIR:=/run/user/$(id --user)}"

# Both are resolved here rather than left to umu, because the prefix directory has to exist on the
#  host before it can be bound into the otherwise empty $HOME. umu's own defaults are
#  GAMEID=umu-default and $HOME/Games/umu/$GAMEID (see umu_run.py, set_env).
export GAMEID=${GAMEID:-umu-default}
export WINEPREFIX=${prefix:-$HOME/Games/umu/$GAMEID}

args=(--die-with-parent --unshare-pid --unshare-uts --cap-drop ALL)
if ((! net)); then
    args+=(--unshare-net)
fi

# Mount a path at its real location, and -- when the argument was a symlink or a relative path --
#  at the name that was passed in too, so the game sees the path it was told about.
bind() {
    local flag=$1 given=$2 real
    real=$(realpath --canonicalize-missing -- "$given")
    args+=("$flag" "$real" "$real")
    if [[ $real != "$given" ]]; then
        args+=("$flag" "$real" "$given")
    fi
}

# System: read-only, and no writable state anywhere in it.
args+=(
    --ro-bind /nix/store /nix/store
    --ro-bind /etc /etc
    --proc /proc
    --dev-bind /dev /dev
    --ro-bind /sys /sys
)
# /run/opengl-driver* is where NixOS keeps the Mesa/Vulkan drivers; /run/udev and /run/nscd are
#  what SDL and glibc's NSS expect to find. Bound individually: /run as a whole holds every other
#  user's runtime dir and the system secrets.
for path in /bin /usr /run/current-system /run/opengl-driver /run/opengl-driver-32 /run/udev /run/nscd; do
    args+=(--ro-bind-try "$path" "$path")
done

# Private /tmp, with the X11 socket directory put back on top of it.
args+=(--tmpfs /tmp --ro-bind-try /tmp/.X11-unix /tmp/.X11-unix)

if ((hosthome)); then
    args+=(--bind "$HOME" "$HOME")
else
    args+=(--tmpfs "$HOME")
    for path in \
        "$WINEPREFIX" \
        "$XDG_DATA_HOME/umu" \
        "$XDG_DATA_HOME/Steam/compatibilitytools.d" \
        "$XDG_CACHE_HOME/umu" \
        "$XDG_CACHE_HOME/umu-protonfixes" \
        "$XDG_CACHE_HOME/protonfixes" \
        "$XDG_CACHE_HOME/Proton" \
        "$XDG_CACHE_HOME/mesa_shader_cache"; do
        mkdir --parents -- "$path"
        bind --bind "$path"
    done
    for path in "$XDG_CACHE_HOME"/radv_builtin_shaders*; do
        if [[ -e $path ]]; then
            bind --bind "$path"
        fi
    done
fi

# Runtime dir: an empty tmpfs with only the display and audio sockets restored. This is the whole
#  point of the exercise -- the real one also carries gnupg, kwallet, ssh-agent and podman sockets.
args+=(--tmpfs "$XDG_RUNTIME_DIR")
for socket in \
    "${WAYLAND_DISPLAY:-wayland-0}" \
    "${WAYLAND_DISPLAY:-wayland-0}.lock" \
    pipewire-0 \
    pipewire-0.lock \
    pulse; do
    if [[ $socket != /* ]]; then
        args+=(--ro-bind-try "$XDG_RUNTIME_DIR/$socket" "$XDG_RUNTIME_DIR/$socket")
    fi
done
if [[ ${WAYLAND_DISPLAY:-} == /* ]]; then
    args+=(--ro-bind-try "$WAYLAND_DISPLAY" "$WAYLAND_DISPLAY")
fi
if [[ -n ${XAUTHORITY:-} ]]; then
    args+=(--ro-bind-try "$XAUTHORITY" "$XAUTHORITY")
fi
if ((dbus)); then
    args+=(--ro-bind-try "$XDG_RUNTIME_DIR/bus" "$XDG_RUNTIME_DIR/bus")
else
    # pressure-vessel binds the session bus socket unconditionally when this variable points at one,
    #  and its own bwrap then dies on the missing source path. Dropping the address is what makes
    #  hiding the socket work at all.
    unset DBUS_SESSION_BUS_ADDRESS
fi

# The game's own directory is writable: saves, ini files and logs live next to the exe often
#  enough that read-only is not worth the support cost. A bare wine verb ('umu-jail wineboot -u')
#  has no directory to bind.
if [[ -e $1 ]]; then
    bind --bind "$(dirname -- "$(realpath --canonicalize-missing -- "$1")")"
fi
for path in ${shares[@]+"${shares[@]}"}; do
    bind --bind "$path"
done
for path in ${ros[@]+"${ros[@]}"}; do
    bind --ro-bind "$path"
done

if ((dryrun)); then
    printf 'bwrap'
    printf ' %q' "${args[@]}" -- umu-run "$@"
    printf '\n'
    exit 0
fi

exec bwrap "${args[@]}" -- umu-run "$@"
