# xmsg-check: two checks over what nix-config renders for xmsg. Realized config is read in a class `into` through
# `outputs` (README stratum 3; template features/headless.nix); content is data: the host names to check.
#
# xmsg-peers: every peers file loads in the xmsg it runs (`xmsg check-peers`, the loader `xmsg serve` uses):
# each host checked against its own node certificate.
# The genie-guard pod's peers ConfigMap is checked too: the pure manifests builder is called with a stand-in secret
# (as k8s/ai/genie-guard-check.nix does) and its `ca` is pointed at the committed root .crt.
#   nix build .#checks.x86_64-linux.xmsg-peers
#
# xmsg-harnesses: opencode reaches xmsg through the module's plugin and has no xmsg MCP server (an `xmsg mcp` child of
# opencode is anonymous), and patch (darwin) runs no `xmsg serve`. Each failing property is printed by name.
#   nix build .#checks.x86_64-linux.xmsg-harnesses
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # nixpkgs evalModules/types for class content (fleet lib is ren.genLib)
  imageRef =
    ns: n:
    let
      a = import (../../../../images + "/${ns}/${n}/default.nix");
    in
    {
      repository = a.imageName;
      digest = a.imageDigest;
    };
  pod = import ../../k8s/ai/_genie-guard-manifests.nix { inherit ren lib; } {
    config.age.secrets.genie-guard-api-key.sopsRef = "ref+sops://stand-in";
    cluster = {
      name = "axon";
      k8s-ai-genie-guard = {
        enable = true;
        hub = "bitstream";
        devHubs = [ ];
      };
    };
    images = {
      "sini/xmsg" = imageRef "sini" "xmsg";
      "sini/genie-guard" = imageRef "sini" "genie-guard";
    };
  };
  podPeers = pod.applications.genie-guard.resources.configMaps.genie-guard-xmsg-peers.data."peers.json";
  root = builtins.path {
    path = ../../../../.secrets/xmsg-ca/root.crt;
    name = "root.crt";
  };
in
{
  ren.classes.xmsgCheck = {
    at = ren.kinds.system;
    into =
      { system, outputs, ... }:
      ms:
      let
        pkgs = system.legacyPackages;
        cfg =
          (lib.evalModules {
            modules = ms ++ [
              {
                options.peerHosts = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
                options.harnessHosts = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
                options.darwinHosts = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
              }
            ];
          }).config;
        nixosOf = h: outputs.nixosConfigurations.${h};
        homeOf = h: (nixosOf h).config.home-manager.users.sini;
        darwinHomeOf = h: outputs.darwinConfigurations.${h}.config.home-manager.users.sini;
        opencodeMcp =
          h:
          (builtins.fromJSON (
            builtins.unsafeDiscardStringContext (homeOf h).home.file.".config/opencode/opencode.json".text
          )).mcp or { };
        properties =
          lib.concatMap (h: [
            {
              name = "${h}: opencode has no xmsg MCP server";
              ok = !(opencodeMcp h ? xmsg);
            }
            {
              name = "${h}: opencode loads the xmsg plugin";
              ok = (homeOf h).xdg.configFile ? "opencode/plugin/xmsg.ts";
            }
          ]) cfg.harnessHosts
          ++ lib.concatMap (h: [
            {
              name = "${h}: no launchd xmsg agent";
              ok = !((darwinHomeOf h).launchd.agents.xmsg.enable or false);
            }
            {
              name = "${h}: no systemd xmsg unit";
              ok = !((darwinHomeOf h).systemd.user.services ? xmsg);
            }
          ]) cfg.darwinHosts;
        failed = map (p: p.name) (lib.filter (p: !p.ok) properties);
        argvOf = h: lib.splitString " " (lib.head (homeOf h).systemd.user.services.xmsg.Service.ExecStart);
        flagOf =
          h: flag:
          let
            argv = argvOf h;
            i = lib.lists.findFirstIndex (a: a == flag) null argv;
          in
          if i == null then throw "xmsg-check: ${h}'s xmsg unit has no ${flag}" else lib.elemAt argv (i + 1);
      in
      {
        checks.drvs.xmsg-peers =
          pkgs.runCommand "xmsg-peers"
            {
              nativeBuildInputs = [
                (homeOf (lib.head cfg.peerHosts)).programs.xmsg.package
                pkgs.jq
              ];
            }
            ''
              ${lib.concatMapStrings (h: ''
                xmsg check-peers ${flagOf h "--peers-file"} --fed-cert ${flagOf h "--fed-cert"}
              '') cfg.peerHosts}
              jq --arg ca ${root} 'map_values(.ca = $ca)' ${pkgs.writeText "pod-peers.json" podPeers} > pod-peers.json
              xmsg check-peers pod-peers.json
              touch $out
            '';

        checks.drvs.xmsg-harnesses = pkgs.runCommand "xmsg-harnesses" { } ''
          failed=${lib.escapeShellArg (lib.concatStringsSep "\n" failed)}
          if [ -n "$failed" ]; then
            printf 'xmsg-harnesses: failed:\n%b\n' "$failed" >&2
            exit 1
          fi
          echo "xmsg-harnesses: ${toString (lib.length properties)} properties hold"
          touch $out
        '';
      };
  };

  ren.aspects.dev-ai-xmsg-check = {
    at = ren.system.x86_64-linux;
    xmsgCheck = {
      peerHosts = [
        "bitstream"
        "cortex"
      ];
      harnessHosts = [
        "bitstream"
        "cortex"
        "blade"
      ];
      darwinHosts = [ "patch" ];
    };
  };
}
