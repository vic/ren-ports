# network: tailnet node that may reach nothing but the LiteLLM proxy
{ ren, ... }:
{
  # Some devices on the Tailnet are not trusted to reach the rest of it: e.g., a work server with other admins on it.
  # It must be reachable from all devices on the tailnet, but must not be able to reach anything in the tailnet itself
  # beyond the LiteLLM proxy (tag:llm).
  #
  # Where this is enforced:
  #  - What it may *reach* is deliberately not configured here. The policy file (terraform/tailscale/config.nix) is the
  #    only place that decides it: the node enrols as "tag:work-server", the one ACL rule naming that tag as `src` is
  #    `tag:work-server -> tag:llm:443`, and the single rule naming it as `dst` is
  #    `autogroup:member -> tag:work-server:22`. Anything set on the host itself is
  #    only as trustworthy as the host, and this one has other root users; the control plane's packet filter does not
  #    care who is root here.
  #  - What it *consumes* from the tailnet is configured here, because once the ACL is in place the homelab is
  #    unreachable from this host, and a pointer to a machine it may not talk to is a stall (DNS timeouts, a dead
  #    exit node), not a restriction.
  #
  # Enrolment is done by tailscaled-autoconnect on the first boot after the switch, from a tagged auth key placed
  # outside the Nix store at /var/lib/tailscale-authkey. Missing it is recoverable rather than fatal: SSH is open on
  # the office LAN too (see the firewall below); but a host that comes up unenrolled is invisible from everywhere
  # except that one network. Put the file there before switching:
  # ```sh
  #    ssh <host> 'sudo install -Dm600 /dev/stdin /var/lib/tailscale-authkey'
  #    nixos-rebuild switch --flake .#fabrica-nixos --target-host <host> --sudo
  # ```
  # On a from-scratch install instead, nixos-anywhere can carry the same file:
  # ```sh
  #    install -Dm600 /dev/stdin /tmp/extra/var/lib/tailscale-authkey
  #    nixos-anywhere --flake .#fabrica-nixos --extra-files /tmp/extra root@<ip>
  # ```
  # Create the key at https://login.tailscale.com/admin/settings/keys as single-use + pre-authorized + tagged
  # "tag:work-server", with the shortest expiry that covers the install. The *key* carries the tag, which is why no
  # --advertise-tags is needed (and why a stale reusable key would be the one thing able to enrol another device as
  # this tag — do not make it reusable). Tagged devices get a node key that never expires, so unlike mensa-nixos this
  # host needs no tailscale_device_key pin. Re-enrolling later (`tailscale up --auth-key …` by hand) does not need
  # the file; tailscaled-autoconnect only reads it while the backend state is NeedsLogin. What must not happen is a
  # plain interactive `tailscale up`: the node then belongs to Adda's *user*, lands in autogroup:member, and the
  # first ACL rule below gives it the whole homelab — verified once by opening fulgur-nixos:22 from this host. The
  # tag is what revokes that, so check `tailscale status` shows "tagged-devices" and not "Adda0@" after any manual
  # login, and fix it with `tailscale up --advertise-tags=tag:work-server --force-reauth …` or by editing the ACL
  # tags in the admin console.
  ren.aspects.network-tailscaleUntrustedNode.nixos =
    {
      fleet,
      lib,
      ...
    }:
    {
      services.tailscale = {
        # Neither an exit node nor a subnet router, and no IP forwarding for one.
        useRoutingFeatures = lib.mkForce "none";

        # No mkForce: the base defaults merges in "--ssh" (identical to --ssh=true) and the parametric
        # "--operator=${user.name}", which is wanted: it gives the account sudoless `tailscale up/set/status`. Safe
        # here: the confinement lives in the control-plane ACL, so no local pref this account can flip grants the node
        # tailnet access. Tailscale SSH is on, in addition to plain sshd on :22, because tailscaled serves it without sshd,
        # PAM,  authorized_keys or the account's shell config. Every way this host can lock itself out (a broken sshd
        # option, an empty authorized_keys after a failed activation, a shell rc that aborts at startup) leaves that path
        # working, and the VM has no serial console to fall back on (Proxmox exposes no serial0; /sys/class/tty/ttyS0/type
        # reads 0). It is what replaces the password authentication this host used to keep enabled for that purpose, which
        # was worse: passwords were accepted on the office LAN and through the WAN forward, not just on the tailnet.
        # Who may use it is decided off-box, in terraform/tailscale/acl.tf's "ssh" block (autogroup:member -> tag:work-server,
        # user ichocholaty, check mode); this flag only offers the service.
        extraSetFlags = [
          "--accept-dns=false"
          "--accept-routes=false"
          "--exit-node="
          "--ssh=true"
        ];

        # The key file is deliberately a path, not a sops secret: this host has no sops key (it is shared with
        #  colleagues), and the file is consumed once on first boot. Delete it afterwards if you like. The unit
        #  short-circuits on BackendState=Running before reading it.
        authKeyFile = "/var/lib/tailscale-authkey";

        # These are what `tailscale up` applies at enrolment. They repeat extraSetFlags on purpose: `up` resets
        #  every pref it is not given, so without them the node would spend its first seconds on the tailnet with
        #  MagicDNS enabled, before tailscaled-set corrects it. Merges with the same the base defaults flags as
        #  extraSetFlags, including the parametric --operator.
        extraUpFlags = [
          "--accept-dns=false"
          "--accept-routes=false"
          "--exit-node="
          "--ssh=true"
        ];
      };

      # The default stub-resolver list leads with MagicDNS (100.100.100.100), whose upstream for non-tailnet names is
      #  mensa-nixos' AdGuard (terraform/tailscale/dns.tf): unreachable under the ACL, and with --accept-dns=false
      #  tailscaled has no upstream to forward to either. Left in place it is a 5 s stall on every lookup (glibc walks
      #  resolv.conf in order), so keep only the two public tiers of the same list.
      networking.nameservers = lib.mkForce [
        (lib.head fleet.plainDns)
        "1.1.1.2"
      ];
      # Nothing here resolves tailnet names in general, so a tailnet search domain would only add a failed lookup to
      #  every unqualified name.
      networking.search = lib.mkForce [ ];

      # The one exception: the LiteLLM proxy, the single tailnet service the ACL lets tag:work-server reach. quad-100
      #  still answers peer names from the netmap with --accept-dns=false (tailscale ipn/ipnlocal/node_backend.go,
      #  "quad-100 can always respond to MagicDNS queries"), and its route is installed regardless, so resolved sends
      #  just this name there; everything else keeps going to the public resolvers above.
      services.resolved.dnsDelegates.litellm.Delegate = {
        DNS = "100.100.100.100";
        Domains = "~litellm.${fleet.tailnet}";
      };

      # The defaults open 80/443 on *every* interface. On an office LAN that is exposure with no upside: this host
      #  serves nothing.
      #
      # SSH is the exception, and it stays open on every interface rather than on tailscale0 alone: the tailnet is
      #  the convenient way in, the office LAN (and the NAT forward in front of it, verifit3.fit.vutbr.cz:6067) is
      #  the one that still works when enrolment fails, tailscaled is down, or the ACL is mid-edit. The VM's serial
      #  console is not a fallback — Proxmox exposes no serial0 for it (/sys/class/tty/ttyS0/type reads 0,
      #  PORT_UNKNOWN), so losing SSH means losing the machine until someone opens noVNC.
      # 22 is written out here instead of relying on services.openssh.openFirewall: that option contributes
      #  `allowedTCPPorts = ports` at the normal priority (100), which this mkForce (50) outranks. An empty list
      #  next to openFirewall = true is a locked-out machine, and nothing warns about it.
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
        allowedUDPPorts = [ ];
      };
    };
}
