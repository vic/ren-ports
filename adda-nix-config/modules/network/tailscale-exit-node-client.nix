# network: route all egress through the mensa-nixos exit node
{ ren, ... }:
{
  ren.aspects.network-tailscaleExitNodeClient.nixos = {
    # mensa-nixos is the *primary* exit node, pinned here declaratively and reasserted on
    #  every boot by tailscaled-set.service.
    #
    # `--exit-node-allow-lan-access` keeps LAN devices (printers, etc.) reachable even
    #  while all other traffic routes out through the exit node.
    #
    # `--advertise-exit-node=false` is REQUIRED here, not cosmetic. tailscaled rejects
    #  prefs that both use and offer an exit node (checkExitNodePrefsLocked in
    #  ipn/ipnlocal/local.go: "Cannot advertise an exit node and use an exit node at the
    #  same time."), and it validates the *merged* result. So any lingering advertisement
    #  — advertisement is stored as default routes in AdvertiseRoutes — makes this whole
    #  `tailscale set` invocation fail at every boot, leaving the host on whatever exit
    #  node it last had. Negating in the same invocation keeps the merged prefs
    #  self-consistent. `calcAdvertiseRoutesForSet` merges against current prefs, so this
    #  strips only the default routes and preserves any subnet routes.
    #
    # Ad-hoc overrides, all reverted to the above on the next boot:
    #   tailscale exit-node list                          # what is available
    #   tailscale set --exit-node=<name>                   # route via some other device
    #   tailscale set --exit-node=auto:any                 # let Tailscale pick
    #   tailscale set --exit-node=                         # no exit node: egress locally
    #   tailscale set --exit-node= --advertise-exit-node   # serve others instead
    # The last one must clear the pin in the same command, for the mutual-exclusion reason
    #  above. Clearing with an empty --exit-node is safe despite --exit-node-allow-lan-access
    #  remaining set: the "can only be used with --exit-node" check lives in `tailscale up`
    #  (prefsFromUpArgs), not `tailscale set`.
    services.tailscale.extraSetFlags = [
      "--exit-node=mensa-nixos"
      "--exit-node-allow-lan-access"
      "--advertise-exit-node=false"
    ];

    # `tailscale set --exit-node=mensa-nixos` resolves that *name* against the current
    #  netmap, but tailscaled-set.service is ordered only after tailscaled.service, which
    #  has usually not finished talking to the control plane yet. The lookup then fails and
    #  — because ExitNodeID persists in tailscaled.state — a temporary override would stick
    #  around indefinitely instead of reverting. Wait for the network and retry.
    systemd.services.tailscaled-set = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      startLimitBurst = 12;
      startLimitIntervalSec = 180;
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
