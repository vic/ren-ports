# vocabulary: one line per live Ren name; `_described.nix` makes a missing or stale line an eval error.
{
  dirs = {
    client = "Desktop and laptop features: programs, emacs, glide, system services";
    common = "What every machine imports: boot, users, sops, impermanence, settings, ...";
    docs = "This README: the old README text plus tables and diagrams from live Ren data";
    flake = "Flake outputs: channels, flake-file, overlays, packages, devshell, formatter, iso, topology";
    helpers = "`ren.helpers`: the old lib.swarselsystems, confLib, vars, globals, distributed config";
    hosts = "One file per machine: `ren.<kind>.<name>` and its aspects; guests in `hosts/<host>/`";
    people = "The users of the fleet";
    platforms = "The classes that build systems: nixos, darwin, homeManager, droid, generic";
    profiles = "Profiles: aspects that only include other aspects";
    server = "Server infrastructure and services; most also write globals and other nodes";
    tests = "VM tests and the sandbox fleet";
    topology = "The kinds (fleet, system, variant, machines, user) and the distributed-config channels";
  };
  kinds = {
    fleet = "Root: repository PII and the static globals file (`swarsel`, `sandbox`)";
    system = "A Nix system: its nixpkgs with the repository overlays, and per-system flake outputs";
    user = "A login on a machine; its home-manager home";
    variant = "The full and the minimal (bootstrap) build of each machine";
    machine = "Abstract: what a host, mac, home and droid share (system, users)";
    host = "A NixOS machine (old hosts/nixos and hosts/utility)";
    guest = "A MicroVM on a host (old `guests/<name>`, node `<host>-<name>`)";
    mac = "A nix-darwin machine";
    home = "A standalone home-manager configuration";
    droid = "A nix-on-droid phone";
    export = "A host that never builds: `nixosModules.default` and `homeModules`";
  };
  channels = {
    globals-defs = "fleet static globals and full host builds -> every scope of the fleet";
    nodes = "full host builds -> the named machine (old `nodes.<name>`)";
    flake-inputs = "any scope -> flake-file class";
    packages = "system and sandbox host -> flake outputs";
    apps = "system -> flake outputs";
    checks = "system -> flake outputs";
    devshells = "system -> flake outputs";
    formatter = "system -> flake outputs";
    flake = "fleet -> top-level flake outputs";
  };
  classes = {
    nixos = "hosts -> nixosConfigurations(Minimal); guests -> their host's `guests`; export -> nixosModules";
    nixos-sandbox = "the sandbox host -> nixosConfigurations.vacanthouse, packages.sandbox-test";
    darwin = "macs -> darwinConfigurations(Minimal)";
    homeManager = "users -> the home of their host, mac, standalone home, droid or export";
    droid = "droids -> nixOnDroidConfigurations";
    generic = "content for every module system -> nixos, darwin, homeManager";
    flake-file = "flake.nix -> packages.write-flake";
    flake-parts = "flake-parts modules per system -> devShells, topology, checks, formatter, packages";
  };
}
