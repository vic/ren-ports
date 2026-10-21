# nixos arm of the nix aspect (daemon policy, OOM slice).
{ ... }:
{
  ren.aspects.nix.nixos =
    { lib, ... }:
    {
      nix = {
        settings = {
          # trusted-users grants root-equivalent nix power (override settings,
          # add substituters, import untrusted store paths): admins only.
          trusted-users = [
            "root"
            "@wheel"
          ];
          # allowed-users only gates who may connect to the daemon; every local
          # login user needs it (HM activation, nix-shell). It is NOT a privilege
          # boundary, so it must not track wheel: decoupled from sudo like login.
          # With mutableUsers = false, local accounts are exactly the resolved
          # registry users, so "*" is precisely the login set.
          allowed-users = [ "*" ];
        };

        gc.dates = "05:00";
        daemonCPUSchedPolicy = lib.mkDefault "batch";
        daemonIOSchedClass = lib.mkDefault "idle";
        daemonIOSchedPriority = lib.mkDefault 7;
      };

      # OOM prevention: separate slice for nix-daemon
      systemd = {
        slices."nix-daemon".sliceConfig = {
          ManagedOOMMemoryPressure = "kill";
          ManagedOOMMemoryPressureLimit = "50%";
          # A pressure policy alone only reacts once the host is already
          # struggling, and it cannot act at all while the kernel still sees
          # swap to hand out. These are the standing bound: High throttles the
          # slice into reclaim, Max fails one build rather than letting the
          # builds take the machine with them. systemd resolves both against
          # physical RAM, so a build host and a small node are bounded in the
          # same proportion without either being named here.
          MemoryHigh = "60%";
          MemoryMax = "85%";
        };
        services."nix-daemon".serviceConfig = {
          Slice = "nix-daemon.slice";
          OOMScoreAdjust = lib.mkDefault 250;
        };
        services.nix-gc.serviceConfig = {
          CPUSchedulingPolicy = "batch";
          IOSchedulingClass = "idle";
          IOSchedulingPriority = 7;
        };
      };
    };
}
