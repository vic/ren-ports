# addaSsh: Adda's SSH client config (~/.ssh/config) with the work hosts and plannotator forwards.
{ ren, ... }:
let
  # plannotator (modules/aspects/ai/default.nix) detects an SSH session via
  #  SSH_CONNECTION/SSH_TTY, then binds its review UI on a fixed loopback port —
  #  exactly so that one standing forward works (packages/server/remote.ts,
  #  DEFAULT_REMOTE_PORT, overridden per host via PLANNOTATOR_PORT in
  #  modules/aspects/work-vm/default.nix) — and skips opening a browser on the remote
  #  side. With this forward in place the printed URL is reachable as-is on the laptop.
  #  Publishing it over the tailnet instead (`plannotator ... --tailscale`) is not an
  #  option here: terraform/tailscale/config.nix only allows tag:work-server on port 22.
  # The port differs per VM and the shared attrset is the single source of truth: with
  #  one port for both, the second concurrent session (to the *other* VM) fails its
  #  forward with "Address already in use" and its URLs land on the first VM's UI.
  # A second session to the *same* host still logs that and continues; the first
  #  session keeps serving the port.
  # Underscore-prefixed so import-tree does not pick it up as an aspect module.
  plannotatorPorts = import ../../work-vm/_plannotator-ports.nix;
  plannotatorForward = hostName: {
    # Explicit bind address: a bare port renders as `[localhost]:<port>` through
    #  home-manager's freeform settings and would bind ::1 as well as 127.0.0.1.
    bind = {
      address = "127.0.0.1";
      port = plannotatorPorts.${hostName};
    };
    host = {
      address = "127.0.0.1";
      port = plannotatorPorts.${hostName};
    };
  };
in
{
  # Adda's SSH *client* config (~/.ssh/config). Home-manager owns that one file and
  #  nothing else in ~/.ssh: private keys, known_hosts and authorized_keys stay
  #  hand-managed/runtime-written exactly as before. The first switch moves the
  #  pre-existing hand-written file to ~/.ssh/config.backup
  #  (home-manager.backupFileExtension = "backup", modules/aspects/defaults.nix) —
  #  check that nothing is missing here afterwards and delete it.
  #
  # Personal rather than generic because every block names a work account and a key
  #  file; that is also why the work VMs do not get this aspect (they include
  #  `addaServer`, and the forwards below are client-side anyway).
  ren.aspects.addaSsh.homeManager = { host, fleet, ... }: {
    programs.ssh = {
      enable = true;

      # The module's legacy `Host *` defaults are off: they warn on every evaluation
      #  and would pin ten directives the hand-written file never set (ForwardAgent,
      #  UserKnownHostsFile, HashKnownHosts, ControlMaster, ...) for every host. The
      #  global block below is the deliberate subset instead.
      enableDefaultConfig = false;

      settings = {
        "*" = {
          # The tailnet hops (fabrica-nixos, and every `nh os switch --target-host`)
          #  otherwise hang silently when a path dies instead of failing: without
          #  keepalives ssh only notices on the next write.
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;

          # Repeated `just host::switch <host>` / rsync / scp runs reuse one TCP+auth
          #  handshake. Side effect worth knowing: a second session to a host that
          #  already has a master attaches to it, so its `LocalForward` is NOT set up
          #  again — no "Address already in use" noise, but the forward belongs to the
          #  first connection and dies with it (ControlPersist keeps it alive 10m
          #  past the last session).
          ControlMaster = "auto";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "10m";
        };

        merlin-xchoch = {
          HostName = "merlin.fit.vutbr.cz";
          User = "xchoch08";
          ForwardX11 = true;
        };

        # IdentitiesOnly on every block that names a key: without it ssh offers the
        #  agent's whole set (seven keys live in ~/.ssh) before the declared one, and
        #  hosts with MaxAuthTries 3 answer "Too many authentication failures" before
        #  the right key is ever tried. Blocks with no IdentityFile deliberately do
        #  NOT get it — there it would disable agent auth outright.
        merlin = {
          HostName = "merlin.fit.vutbr.cz";
          User = "ichocholaty";
          IdentityFile = "~/.ssh/id_fit_ichocholaty";
          IdentitiesOnly = true;
        };

        eva = {
          HostName = "eva.fit.vutbr.cz";
          User = "xchoch08";
          ForwardX11 = true;
        };

        kazi = {
          HostName = "kazi.fit.vutbr.cz";
          User = "ichocholaty";
          IdentityFile = "~/.ssh/id_fit_ichocholaty";
          IdentitiesOnly = true;
        };

        "minerva1.fit.vutbr.cz" = {
          HostName = "minerva1.fit.vutbr.cz";
          User = "xchoch08";
        };

        barbora = {
          HostName = "barbora.it4i.cz";
          User = "xchoch08";
          ForwardX11 = true;
          IdentityFile = "~/.ssh/id_rsa";
          IdentitiesOnly = true;
        };

        karolina = {
          HostName = "karolina.it4i.cz";
          User = "xchoch08";
          ForwardX11 = true;
          IdentityFile = "~/.ssh/id_rsa";
          IdentitiesOnly = true;
        };

        verifit_vojta_stul = {
          HostName = "pc012170.fit.vutbr.cz";
          Port = 6075;
          User = "xchoch08";
          IdentityFile = "~/.ssh/id_rsa_verifit_server";
          IdentitiesOnly = true;
        };

        # Every flake host is a tailnet node named `<name>-nixos`; HostName pins its
        #  MagicDNS FQDN. A bare label goes through the resolv.conf search list, and
        #  resolved races every domain in it: the home router answers *any* `<x>.home`
        #  with 0.0.0.17/::17, so about half the lookups of `nomen-nixos` landed there
        #  ("connect to host nomen-nixos port 22: Permission denied"); the campus DNS can
        #  win the same way. The local host is excluded so that `just host::switch`
        #  without a host keeps going over loopback sshd instead of the tailnet.
        "*-nixos !${host.name}".HostName = "%h.${fleet.tailnet}";

        # The work VMs in the VeriFIT Proxmox (harena-nixos is a clone of
        #  fabrica-nixos). Named exactly like the flake's host attributes so that
        #  `just host::switch fabrica-nixos` / `nh os switch --target-host harena-nixos`
        #  resolve them.
        # This block also picks the account, since the local user is adda and the work
        #  account is ichocholaty.
        fabrica-nixos = {
          User = "ichocholaty";
          IdentityFile = "~/.ssh/id_verifit_server";
          IdentitiesOnly = true;
          LocalForward = [ (plannotatorForward "fabrica-nixos") ];
        };

        # Same machine over the campus network, for when the tailnet is unavailable or
        #  the tailscaled on it is down: 6067 is a port forward on verifit3 to the VM's
        #  :22. AddressFamily inet because verifit3's AAAA record is not reachable from
        #  here.
        fabrica-wan = {
          HostName = "verifit3.fit.vutbr.cz";
          Port = 6067;
          User = "ichocholaty";
          IdentityFile = "~/.ssh/id_verifit_server";
          IdentitiesOnly = true;
          AddressFamily = "inet";
          LocalForward = [ (plannotatorForward "fabrica-nixos") ];
        };

        harena-nixos = {
          User = "ichocholaty";
          IdentityFile = "~/.ssh/id_verifit_server";
          IdentitiesOnly = true;
          LocalForward = [ (plannotatorForward "harena-nixos") ];
        };

        # Same, over the campus network: 6071 is harena-nixos' own forward on verifit3.
        harena-wan = {
          HostName = "verifit3.fit.vutbr.cz";
          Port = 6071;
          User = "ichocholaty";
          IdentityFile = "~/.ssh/id_verifit_server";
          IdentitiesOnly = true;
          AddressFamily = "inet";
          LocalForward = [ (plannotatorForward "harena-nixos") ];
        };

        mata = {
          HostName = "verifit3.fit.vutbr.cz";
          Port = 6080;
          User = "ichocholaty";
          IdentityFile = "~/.ssh/id_verifit_server";
          IdentitiesOnly = true;
          AddressFamily = "inet";
        };
      };
    };
  };
}
