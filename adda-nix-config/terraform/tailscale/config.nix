# Tofunix module generating the tailnet's OpenTofu configuration — the successor of the
#  hand-written *.tf files that used to live next to this file. The provider options are
#  generated from the tailscale provider's own schema (see modules/tofunix.nix), so
#  attribute names below mirror the HCL names one-to-one.
{ ref, ... }:
{
  # Credentials come from the environment, never from files in this repo.
  #  secrets/tailscale-terraform.env (sops-encrypted) holds
  #  TAILSCALE_OAUTH_CLIENT_ID/TAILSCALE_OAUTH_CLIENT_SECRET/TAILSCALE_TAILNET
  #  and TF_VAR_mensa_nixos_tailnet_ip (see the variable below); the `.envrc` in this
  #  directory decrypts and exports them automatically via direnv, so they're available
  #  whenever you cd into it. Edit real values in with
  #  `sops secrets/tailscale-terraform.env` (the OAuth client itself is created at
  #  https://login.tailscale.com/admin/settings/oauth with "Policy File" and
  #  "Devices: Core" write scopes).
  provider.tailscale.default = { };

  variable.mensa_nixos_tailnet_ip = {
    description = "mensa-nixos's tailnet IPv4 address (`tailscale ip -4` on mensa-nixos, or the admin console's Machines list). Supplied via TF_VAR_mensa_nixos_tailnet_ip in secrets/tailscale-terraform.env.";
    type = "string";
  };

  # Replaces the admin console's DNS page: MagicDNS stays on, and mensa-nixos's
  #  resolver becomes the tailnet-wide nameserver for every device (see
  #  addax.services.technitium in modules/aspects/services/technitium.nix).
  # Setting a global nameserver here is what makes Tailscale override each
  #  device's local DNS while connected — there's no separate toggle for it.
  resource.tailscale_dns_preferences.this.magic_dns = true;
  resource.tailscale_dns_nameservers.this.nameservers = [ ref.var.mensa_nixos_tailnet_ip ];

  # mensa-nixos is user-owned rather than tagged (the reasoning lives in
  #  modules/hosts/mensa-nixos/system.nix: a tag strips the device's user identity, and
  #  caddy-tailscale's tailscale_auth rejects tagged nodes, which would lock the host out of
  #  every service it hosts). Tagged devices get one thing for free that user-owned ones do
  #  not — a node key that never expires — so pin that explicitly here. Without it a headless
  #  server silently drops off the tailnet 180 days after enrolment, and the setting is
  #  otherwise a manual toggle in the admin console.
  #
  # The device must already be enrolled for this to resolve; `wait_for` covers the window
  #  right after a reinstall, when `tailscale up` has been run but the record is not yet
  #  visible to the API.
  data.tailscale_device.mensa_nixos = {
    hostname = "mensa-nixos";
    wait_for = "60s";
  };
  resource.tailscale_device_key.mensa_nixos = {
    # ref.* only tracks attributes set literally in this module; node_id is computed,
    #  so spell the interpolation out instead of using ref.data.
    device_id = "\${data.tailscale_device.mensa_nixos.node_id}";
    key_expiry_disabled = true;
  };

  # The tailnet's current policy file, plus an "autoApprovers.exitNode" entry so exit
  #  nodes are approved without a manual click in the admin console.
  resource.tailscale_acl.this = {
    overwrite_existing_content = true;
    acl = ''
      {
      	// Declare static groups of users. Use autogroups for all users or users with a specific role.
      	// "groups": {
      	//   "group:example": ["alice@example.com", "bob@example.com"],
      	// },

      	// Define the tags which can be applied to devices and by which users.
      	"tagOwners": {
      		"tag:homelab-caddy": ["autogroup:admin"],
      		// The work VMs (modules/aspects/work-vm, worn by fabrica-nixos and
      		//  harena-nixos): machines with other admins on them. They are tagged precisely
      		//  to take them *out* of autogroup:member — a tag replaces the device's user
      		//  identity, so it stops inheriting Adda's access and is reachable only through
      		//  the one rule that names the tag below. Nothing here is per-machine: a new
      		//  work VM only needs its own tag:work-server auth key, not an ACL change.
      		// Both autogroups: "autogroup:admin" does not contain the Owner role, which is
      		//  what Adda holds, and the tag must be applicable by him at `tailscale up`.
      		"tag:work-server": ["autogroup:owner", "autogroup:admin"],
      		// The LiteLLM proxy's caddy-tailscale node on mensa-nixos
      		//  (modules/aspects/services/litellm.nix). Its own tag rather than tag:homelab-caddy
      		//  because it is the one service the work servers may reach, and a dst can only name
      		//  it if nothing else carries the tag. Applied by a dedicated reusable auth key
      		//  (TS_AUTHKEY_LITELLM in secrets/services-tailscale-tsauthkey.env).
      		"tag:llm": ["autogroup:owner", "autogroup:admin"],
      	},

      	// Exit-node approval without a manual admin-console click, for any device Adda owns —
      	//  mensa-nixos (the permanent primary, see modules/hosts/mensa-nixos/system.nix) and any
      	//  laptop or phone temporarily promoted with `tailscale set --advertise-exit-node`, which
      	//  is then live immediately. Trade-off: an *accidental* advertisement is also live
      	//  immediately, which is acceptable on a single-person private tailnet.
      	// Both autogroups are listed because they are not the same set and Adda holds the Owner
      	//  role: "autogroup:admin" is only users whose role is literally Admin.
      	// There is deliberately no "tag:exit-node" here. Tagging mensa-nixos would take its user
      	//  identity away and caddy-tailscale's tailscale_auth rejects tagged nodes, locking the
      	//  host out of its own caddy-fronted services.
      	"autoApprovers": {
      		"exitNode": ["autogroup:owner", "autogroup:admin"],
      	},

      	// Define access control lists for users, groups, autogroups, tags,
      	// Tailscale IP addresses, and subnet ranges.
      	"acls": [
      		// Previously this was src ["*"] -> dst ["*:*"]. It is enumerated now for one
      		//  reason: Tailscale ACLs are allow-only, there is no deny rule, so the only way
      		//  to keep a device out of the tailnet is to leave it out of every `src`. A
      		//  wildcard would hand tag:work-server access to everything.
      		// This rule is the old behaviour with tag:work-server removed from both ends:
      		//  Adda's own (untagged) devices plus tag:homelab-caddy, the caddy-tailscale
      		//  service nodes (paperless, ntfy, nextcloud, freshrss, pinepods, adguard), talk
      		//  to each other freely; tag:llm (litellm) is one more of those service nodes.
      		// The funnel-ingress-node peers visible in `tailscale status` carry tag:ingress,
      		//  which is Tailscale's own internal tag: it cannot be declared in tagOwners and
      		//  the API rejects it here ("src=tag not found"). Funnel is not enabled by this
      		//  policy (no "funnel" nodeAttr), so it needs no rule.
      		{
      			"action": "accept",
      			"src":    ["autogroup:member", "tag:homelab-caddy"],
      			"dst":    ["autogroup:member:*", "tag:homelab-caddy:*", "tag:llm:*"],
      		},

      		// Exit-node traffic. Routing through mensa-nixos is not covered by the rule
      		//  above: an exit node's destination is the public internet, which the policy
      		//  addresses as autogroup:internet, not as the exit node's own tailnet IP. The
      		//  old src ["*"] -> dst ["*:*"] rule covered it implicitly, so enumerating the
      		//  acls silently broke every service that egresses through mensa-nixos.
      		// autogroup:member only: tag:work-server must not reach the internet through
      		//  Adda's home connection, which is also why that host sets "--exit-node=".
      		{
      			"action": "accept",
      			"src":    ["autogroup:member"],
      			"dst":    ["autogroup:internet:*"],
      		},

      		// The work servers: SSH in from Adda's own devices, and the agents on them out to
      		//  the LiteLLM proxy over HTTPS; nothing else, in either direction. The rule below
      		//  is the only one naming tag:work-server as `src`, which is what stops them reaching
      		//  the rest of the homelab; that they also cannot be reached on any port but 22
      		//  limits what a compromised colleague account can scan from there.
      		// Note it still *sees* Adda's devices in its netmap (hostnames and 100.x
      		//  addresses): a node needs its peers' keys to accept their connections, so this
      		//  is unavoidable inside one tailnet. Only a separate tailnet hides that.
      		{
      			"action": "accept",
      			"src":    ["autogroup:member"],
      			"dst":    ["tag:work-server:22"],
      		},
      		// litellm has no tailscale_auth (it rejects every tagged node), so this rule is the
      		//  whole gate. What it hands out: the CERIT key the proxy holds, which these hosts
      		//  could decrypt themselves before the proxy existed, and Claude passthrough, which
      		//  needs the caller's own subscription token.
      		{
      			"action": "accept",
      			"src":    ["tag:work-server"],
      			"dst":    ["tag:llm:443"],
      		},

      		// Allow users in "group:example" to access "tag:example", but only from
      		// devices that are running macOS and have enabled Tailscale client auto-updating.
      		// {"action": "accept", "src": ["group:example"], "dst": ["tag:example:*"], "srcPosture":["posture:autoUpdateMac"]},
      	],

      	// Define postures that will be applied to all rules without any specific
      	// srcPosture definition.
      	// "defaultSrcPosture": [
      	//      "posture:anyMac",
      	// ],

      	"nodeAttrs": [
      		{
      			"target": ["autogroup:member"],
      			"attr":   ["drive:share", "drive:access"],
      		},
      	],

      	"grants": [
      		// Taildrive, between Adda's own devices only — "*" would also name
      		//  tag:work-server. Harmless today (the acls above give it no path to any of
      		//  these devices, and nodeAttrs only grants drive:access to autogroup:member) but
      		//  it is a capability handed to a machine with other admins on it; don't.
      		{
      			"src": ["autogroup:member"],
      			"dst": ["autogroup:member"],

      			"app": {
      				"tailscale.com/cap/drive": [
      					{
      					"shares": ["*"],
      					"access": "rw",
      					},
      				],
      			},
      		},

      		// tsidp's app capability gates its own admin UI and dynamic client registration;
      		//  the ACL above grants network reach, this grants identity-admin rights on idp itself.
      		//  Only Adda's devices — the work VMs can reach tag:llm for LiteLLM, but someone rooted
      		//  on them must still not be able to mint OIDC clients or enrol admin users into tsidp.
      		{
      			"src": ["autogroup:member"],
      			"dst": ["tag:homelab-caddy"],

      			"app": {
      				"tailscale.com/cap/tsidp": [
      					{
      						"allow_admin_ui": true,
      						"allow_dcr": true,
      						"users":     ["autogroup:member"],
      						"resources": ["*"],
      					},
      				],
      			},
      		},
      	],

      	// Define device posture rules requiring devices to meet
      	// certain criteria to access parts of your system.
      	// "postures": {
      	//      // Require devices running macOS, a stable Tailscale
      	//      // version and auto update enabled for Tailscale.
      	//  "posture:autoUpdateMac": [
      	//      "node:os == 'macos'",
      	//      "node:tsReleaseTrack == 'stable'",
      	//      "node:tsAutoUpdate",
      	//  ],
      	//      // Require devices running macOS and a stable
      	//      // Tailscale version.
      	//  "posture:anyMac": [
      	//      "node:os == 'macos'",
      	//      "node:tsReleaseTrack == 'stable'",
      	//  ],
      	// },

      	// Define users and devices that can use Tailscale SSH.
      	"ssh": [
      		// Allow all users to SSH into their own devices in check mode.
      		// Comment this section out if you want to define specific restrictions.
      		{
      			"src":    ["autogroup:member"],
      			"dst":    ["autogroup:self"],
      			"users":  ["autogroup:nonroot", "root"],
      			"action": "accept",
      		},

      		// The work servers need their own rule: a tagged node has no user owner, so it is
      		//  not in autogroup:self and the rule above does not reach it.
      		// This is a second way in beside plain sshd on :22, and that is the point —
      		//  tailscaled serves it itself, without sshd, PAM, authorized_keys or the
      		//  account's shell config, so it survives the failure that locks the other path
      		//  out. That matters here because the VMs have no serial console (Proxmox exposes
      		//  no serial0 for them), and it is what makes removing password authentication
      		//  from modules/aspects/work-vm safe.
      		// "accept", not "check": no periodic browser re-authentication — the session is a
      		//  standing capability, gated only by tailnet membership and the src rule. The
      		//  trade-off this accepts: the box has other root users and this path is
      		//  authorised entirely off-box, so a stolen node key is a standing shell; what
      		//  limits the blast radius is that tag:work-server appears as `src` only in the
      		//  tag:llm:443 rule, so the box itself reaches nothing else. Deploys use plain
      		//  sshd anyway.
      		// Only ichocholaty, and no "root": root login is refused by sshd on this host
      		//  (PermitRootLogin = "no" in the defaults) and there is no reason for the other
      		//  path to be more permissive than the one it backs up. `sudo` still works.
      		{
      			"src":    ["autogroup:member"],
      			"dst":    ["tag:work-server"],
      			"users":  ["ichocholaty"],
      			"action": "accept",
      		},
      	],

      	// Tailscale evaluates these on every save/apply and refuses the policy if one fails,
      	//  so they are the actual guarantee behind "the work server can be reached on SSH and
      	//  can reach nothing but the LiteLLM proxy". Destinations must be a tag or a literal
      	//  IP — test syntax resolves neither MagicDNS names nor autogroups.
      	"tests": [
      		// 1.1.1.1 stands in for "somewhere on the public internet", which is how an exit
      		//  node's traffic is matched. It is here because dropping autogroup:internet is
      		//  exactly the regression that enumerating the acls introduced once already, and
      		//  nothing else in this file would have caught it.
      		{
      			"src":    "Adda0@github",
      			"accept": ["tag:work-server:22", "''${var.mensa_nixos_tailnet_ip}:443", "tag:llm:443", "1.1.1.1:443"],
      			"deny":   ["tag:work-server:80", "tag:work-server:443"],
      		},
      		{
      			"src":    "tag:work-server",
      			"accept": ["tag:llm:443"],
      			"deny":   ["''${var.mensa_nixos_tailnet_ip}:22", "''${var.mensa_nixos_tailnet_ip}:443", "tag:homelab-caddy:443", "tag:llm:22", "1.1.1.1:443"],
      		},
      	],
      }
    '';
  };
}
