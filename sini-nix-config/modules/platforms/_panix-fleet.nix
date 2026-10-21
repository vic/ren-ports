# panix fleet module (ex batteries/panix/panix.nix options+fleets). Evaluated by platforms/panix.nix with
# specialArgs.panixHosts = { <name> = { system; deployment; intoAttr; fragments; }; } and config.den.panix.* kept as-is
# so _panix-settings.nix / _panix-hardened.nix stay verbatim.
{ lib, config, panixHosts, systems, ... }:
let
  inherit (lib) mkOption types;
  cfg = config.den.panix;
  urlSentinel = "@PANIX_FLAKE_URL@";
  # never a machine's ssh.hostname, so no machine is treated as local
  localSentinel = "panix-no-local-machine.invalid";
  # mkDefault on every leaf so a fragment setting one field keeps the defaults beside it
  mkDefaults = v: if builtins.isAttrs v then lib.mapAttrs (_: mkDefaults) v else lib.mkDefault v;
  globalDefaults = {
    flags = {
      local_machine_hostname = localSentinel;
      runtime.max_concurrency = cfg.maxConcurrency;
    };
    fleet = {
      ssh = {
        # panix would add StrictHostKeyChecking=accept-new ahead of extra_flags; ssh takes the first value
        disable_auto_add_host_key = true;
        extra_flags = [ "-o" "StrictHostKeyChecking=yes" "-o" "BatchMode=yes" "-o" "ConnectTimeout=10" "-o" "ServerAliveInterval=15" ];
      }
      // lib.optionalAttrs (cfg.knownHostsFile != null) { known_hosts_file = cfg.knownHostsFile; };
      bootstrap.disable_nix_install = true;
      auto_rollback = false;
    };
    fleet.flakes.${cfg.flakeName}.url = if cfg.flakeUrl == null then urlSentinel else cfg.flakeUrl;
  };
  hostDefaults = deployerSystem: host:
    let p = cfg.pathOf host;
    in {
      fleet.flakes.${p.flake}.installables.${p.outputType}.${p.installable} = {
        # panix takes build_mode at installable level at the closest
        nix.build_mode = if host.system == deployerSystem then "local" else "remote";
        machines.${p.machine} = {
          ssh = { hostname = host.deployment.address; username = host.deployment.user; };
          inherit (host.deployment) tags;
        };
      };
    };
in
{
  options.den.panix = {
    flakeName = mkOption { type = types.strMatching "[a-z0-9-]+"; default = "self"; description = "Key under fleet.flakes (also a panix tag)."; };
    flakeUrl = mkOption { type = types.nullOr types.str; default = null; description = "null: the wrapper fills in git+file://<repo root>."; };
    knownHostsFile = mkOption { type = types.nullOr (types.strMatching "/.*"); default = null; description = "Absolute fleet ssh.known_hosts_file."; };
    maxConcurrency = mkOption { type = types.ints.positive; default = 4; description = "flags.runtime.max_concurrency."; };
    settings = mkOption { type = types.deferredModule; default = { }; description = "Settings module merged into every fleet."; };
    pathOf = mkOption {
      type = types.functionTo (types.attrsOf types.str);
      readOnly = true;
      internal = true;
      description = "Host -> { flake, outputType, installable, machine }, its keys in panix.yml.";
      default = host: {
        flake = cfg.flakeName;
        outputType = lib.head host.intoAttr;
        installable = lib.concatStringsSep "." (lib.tail host.intoAttr);
        machine = host.name;
      };
    };
    urlSentinel = mkOption { type = types.str; readOnly = true; default = urlSentinel; description = "Wrapper substitution marker."; };
  };
  config.den.panix.fleets = lib.genAttrs systems (system: _: {
    imports = [ cfg.settings (mkDefaults globalDefaults) ]
      ++ lib.mapAttrsToList (_: h: mkDefaults (hostDefaults system h)) panixHosts
      ++ lib.concatMap (h: h.fragments) (lib.attrValues panixHosts);
  });
}
