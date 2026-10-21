# Shoko LuaRenamer plugin, installed declaratively onto the config PVC (5.3.x stable has no in-app
# plugin manager; LuaRenamer can branch the destination folder on media type, unlike WebAOM).
# Pinned to the stable build targeting Shoko abstractions 5.3.1 (compatible with server 5.3.3). The
# release URL uses the git tag, the asset filename carries the full `git describe` suffix; bump both
# together (https://github.com/Mik1ll/LuaRenamer/releases). Idempotent via a per-version marker, so
# restarts need no network. curl -L required (assets 302 to a CDN; busybox wget will not follow).
# Files are chown'd to the shoko uid (1027:65536). alpine runs as root to apk-add and chown;
# globalMounts on the config PVC reach init containers.
{ ... }:
let
  luaRenamerTag = "v5.10.3-stable-5.3.1";
  luaRenamerAsset = "LuaRenamer_${luaRenamerTag}-0-g4f8f6bb_linux-x64.zip";
in
{
  ren.aspects.k8s-media-shoko.k8s-manifests =
    { images, ... }:
    {
      applications.shoko.helm.releases.shoko.values.controllers.main.initContainers.install-luarenamer = {
        image = {
          inherit (images."library/alpine") repository digest;
        };
        command = [
          "/bin/sh"
          "-c"
          ''
            set -eu
            dst=/home/shoko/.shoko/Shoko.CLI/plugins
            marker="$dst/LuaRenamer/.installed-${luaRenamerTag}"
            if [ -f "$marker" ]; then
              echo "LuaRenamer ${luaRenamerTag} already present; skipping."
              exit 0
            fi
            echo "Installing LuaRenamer ${luaRenamerTag}..."
            apk add --no-cache curl unzip
            mkdir -p "$dst"
            rm -rf "$dst/LuaRenamer"
            curl -fL "https://github.com/Mik1ll/LuaRenamer/releases/download/${luaRenamerTag}/${luaRenamerAsset}" -o /tmp/lr.zip
            unzip -o /tmp/lr.zip -d "$dst"
            chown -R 1027:65536 "$dst/LuaRenamer"
            touch "$marker"
            echo "LuaRenamer ${luaRenamerTag} installed."
          ''
        ];
      };
    };
}
