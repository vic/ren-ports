# Alloy service unit, split from alloy.nix; same aspect (aspects merge across files).
{ ... }:
{
  ren.aspects.svc-alloy.nixos =
    {
      config,
      environment,
      lib,
      monitoring-ingest,
      pkgs,
      ...
    }:
    let
      ingest = lib.findFirst (i: i.cluster == environment.monitoring.ingest) null monitoring-ingest;
    in
    lib.mkIf (ingest != null) {
      services.alloy = {
        enable = true;
        extraFlags = [ "--disable-reporting" ];
      };

      # Shared with the ingest proxy, which holds the derived htpasswd.
      # Declared here rather than as age-secrets so microvm guests get it too.
      # Read by systemd for LoadCredential, so root-owned.
      age.secrets.alloy-ingest-password.rekeyFile = ingest.passwordFile;

      # grafana-alloy dlopens systemd-minimal-libs, built without compression, which silently
      # skips every zstd-compressed journal file. The loader searches LD_LIBRARY_PATH before RUNPATH.
      systemd.services.alloy.environment.LD_LIBRARY_PATH = "${lib.getLib pkgs.systemd}/lib";

      systemd.services.alloy.serviceConfig = {
        LoadCredential = "ingest-password:${config.age.secrets.alloy-ingest-password.path}";
        # Not the module's "alloy": on the k3s nodes /var/lib/alloy is the in-cluster log
        # DaemonSet's hostPath, and a DynamicUser state directory needs that name free.
        StateDirectory = lib.mkForce "alloy-host";
        WorkingDirectory = lib.mkForce "%S/alloy-host";
      };
    };
}
