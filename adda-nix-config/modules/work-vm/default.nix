# work-vm: everything the VeriFIT Proxmox work VMs have in common (host half `workVM`, user half `workVM-user`)
{ ren, ... }:
{
  # Everything the VeriFIT Proxmox work VMs have in common. There is more than one of
  #  them because the second (`harena-nixos`) is a Proxmox clone of the first
  #  (`fabrica-nixos`): same virtual hardware, same disk image, same account, reachable
  #  through its own NAT forward on verifit3 (:6067 for fabrica, :6071 for harena).
  #  Anything that is genuinely per-machine — the hostname and the registry entry —
  #  stays in modules/hosts/<host>/system.nix; everything else lives here so the two
  #  cannot drift apart.
  ren.aspects.workVM = {
    nixos =
      { host, lib, ... }:
      {
        imports = [
          ./_hardware.nix
        ];

        # The VM boots with SeaBIOS: GRUB's core image goes into the MBR gap of /dev/sda and there is no ESP at all.
        # modules/defaults.nix assumes the opposite for every host (device = "nodev", efiSupport, canTouchEfiVariables)
        # and all three must be countered; an EFI install on a BIOS machine produces a VM that never boots, with no
        # console message explaining why.
        # useOSProber is off because it is only useful next to another OS, and it would otherwise run os-prober on every
        # generation of a single-OS VM.
        boot.loader.grub = {
          device = lib.mkForce "/dev/sda";
          efiSupport = lib.mkForce false;
          useOSProber = lib.mkForce false;
        };
        boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

        # modules/defaults.nix sets timeout = null, "remain in the boot menu
        #  indefinitely" — fine on a laptop in front of you, fatal here: a headless VM
        #  never finishes booting after a power event or a Proxmox restart, and nothing
        #  says so. Caught in a `--vm-test` run of this configuration, which came up and
        #  then hung at "GRUB loading."
        boot.loader.timeout = lib.mkForce 3;

        # No `services.xserver.enable = mkForce false` / `services.printing.enable =
        #  mkForce false` here any more: X, CUPS, the GPU stack, pipewire, fonts,
        #  firmware/fwupd, bluetooth, NetworkManager and the xanmod kernel left
        #  modules/defaults.nix and became aspects (modules/aspects/{desktop,audio,
        #  fonts,hardware,kernel,network}), which these hosts simply do not include.
        #  Anything that has to be switched off by force here is a sign something
        #  workstation-shaped crept back into the defaults.

        # Taking over a machine that is not yet running this flake (a stock
        #  nixos-generate-config install) has to be pushed to `root@`, not to
        #  `ichocholaty@`: its `trusted-users` is just `root`, so its daemon rejects
        #  every locally built path with "cannot add path '...' because it lacks a
        #  signature by a trusted key". Install the deploy key for root once
        #  (`ssh -t <host> 'sudo install -d -m700 /root/.ssh && sudo install
        #  -m600 ~/.ssh/authorized_keys /root/.ssh/'`, PermitRootLogin is
        #  "prohibit-password" there), then
        #  `nh os boot --hostname <host> --target-host root@<host> --use-substitutes`.
        #  Afterwards this configuration applies, `trusted-users` from
        #  modules/defaults.nix is `root @wheel`, ichocholaty is in wheel, and plain
        #  `just host::switch <host>` works — root's authorized_keys can be removed
        #  again at that point (the defaults set PermitRootLogin = "no" anyway, so
        #  after the switch it is dead weight). A VM cloned from a host that already
        #  runs this flake skips all of that: it boots with the clone's `trusted-users`
        #  and its account is already in wheel.

        # The key Adda actually reaches these boxes with is work-specific
        #  (~/.ssh/id_verifit_server) and is the one already in the pre-flake
        #  ~/.ssh/authorized_keys; modules/users/adda/user.nix installs a different one.
        #  Listed in addition, not instead, because the switch to this flake replaces
        #  that file wholesale: drop it and the forwarded ports on verifit3
        #  (:6067 and :6071 -> the VMs' :22) stop accepting the key that is in use
        #  right now, which is also the only way in that does not depend on tailnet
        #  enrolment having succeeded.
        users.users.${(builtins.head host.users).name}.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBzuiBRoMaM0IjOU6Bn1gdORaEbf+MEB6/HdA+R2Az+w adda@fulgur-nixos"
        ];
      };

    includes = with ren.aspects; [
      # QEMU guest agent, virtio initrd drivers, serial console, and the bare-metal defaults (firmware, fwupd, bluetooth,
      # suspend) that a VM has no use for.
      virtualisation-proxmoxGuest

      # Joins the tailnet as tag:work-server: reachable over SSH from personal devices, and reaching nothing in the
      # tailnet but the LiteLLM proxy its agents use (tag:llm). The actual restriction lives in
      # terraform/tailscale/config.nix; this only keeps the host from depending on tailnet services it may not reach.
      # Deliberately *not* network.tailscaleExitNodeClient: a work machine must not egress through mensa-nixos.
      # Every host including this aspect needs its own single-use, pre-authorized,
      #  tag:work-server auth key in /var/lib/tailscale-authkey before the first switch —
      #  a clone must also have the source VM's /var/lib/tailscale wiped first, or the two
      #  machines claim the same node key.
      network-tailscaleUntrustedNode
    ];
  };

  # The user half of the same role: not the full `adda` aspect, because these boxes are
  #  headless and shared with colleagues, so they get no desktop, no syncing and no
  #  personal credentials beyond the scoped GitHub token (the agents below hold no
  #  provider keys; they go through mensa-nixos' LiteLLM proxy). `addaServer`
  #  carries no sops support of its own, hence `security.sops` here (the aspect that
  #  imports sops-nix and points its age identity at /etc/ssh/ssh_host_ed25519_key).
  ren.aspects.workVM-user.homeManager =
    { host, ... }:
    {
      # plannotator binds its review UI on a fixed loopback port when it is run over
      #  SSH, so the laptop can keep one standing forward per host. Both VMs defaulting
      #  to 19432 made the second forward fail ("Address already in use") and the URL
      #  printed on one VM reach the other; one port per host fixes that.
      # Underscore-prefixed so import-tree does not pick it up as an aspect module.
      home.sessionVariables.PLANNOTATOR_PORT = toString (import ./_plannotator-ports.nix).${host.name};
    };

  ren.aspects.workVM-user.includes = with ren.aspects; [
    addaServer

    security-sops
    security-gpg

    console-atuin
    console-eza
    console-terminalMultiplexers
    vcs

    # Whole umbrella, not just `ai.claude`/`ai.omp`: claude.nix registers the
    #  plannotator hook and the plannotator/tuicr skills unconditionally, and both
    #  shell out to CLIs that only the umbrella installs — picking the two agent
    #  aspects alone leaves those hooks pointing at binaries that are not on PATH.
    #  plannotator's review UI is a local web server, so it needs an SSH port
    #  forward from this VM; herdr comes along and is a plain TUI. `ai.ollama` is
    #  not part of the umbrella (it wants a ROCm GPU and a Flatpak desktop app).
    ai

    languages-c-cpp
    languages-python
    languages-nix
    languages-latex
    languages-markdown
  ];
}
