# vocabulary of the readme directory map: one line per directory of modules/; `_described.nix` fails eval on a missing or stale line.
{
  ai = "Claude, omp, ollama, herdr and voxtype, with the shared AI rules.";
  audio = "PipeWire audio stack.";
  community = "Placeholder for modules shared with others; empty for now.";
  console = "Shells, terminal tools, multiplexers and version control.";
  desktop = "Desktop environments, browsers, games, flatpak and nix-ld.";
  development = "Android tooling and general development packages.";
  docs = "This README: generator, fleet graphs and vocabulary.";
  editors = "Helix, Zed, VSCodium, NvChad, JetBrains, and the editor contribution classes and channels.";
  features = "Defaults every host or user gets: base, accounts, overlays, packages, networking, state version.";
  filesystems = "Extra filesystem support (NTFS).";
  flake = "Flake outputs: channels, files class, flake-file, devshell, formatter, tests, tofunix, templates.";
  hardware = "Hardware aspects: bare metal and CPU power handlers.";
  hosts = "One directory per NixOS host: the `ren.host` instance, its aspect and hardware.";
  kernel = "The xanmod kernel.";
  languages = "Language toolchains. Each also contributes editor settings and extensions.";
  media = "Books, music, podcasts and other media apps.";
  misc = "Small desktop services: fonts, KDE Connect, Syncthing, xremap, autologin.";
  network = "NetworkManager, Portmaster and the Tailscale client roles.";
  people = "The users: `adda` (personal) and `ichocholaty` (work).";
  platforms = "The classes that build systems: nixos, os, account, homeManager, aliases, abbreviations.";
  security = "GPG, sops, ClamAV.";
  services = "Homelab services and the caddy reverse proxy.";
  swap = "Swap aspects driven by the host `swap` record.";
  topology = "The kinds: fleet, system, host, user.";
  virtualisation = "VM guests, Proxmox, Waydroid and bootable VM images.";
  work-vm = "The headless work VM profile.";
}
