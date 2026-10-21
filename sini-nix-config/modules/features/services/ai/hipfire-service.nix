# hipfire: upstream services.hipfire wired to the typed settings; models come from the store.
{
  ren,
  inputs,
  lib,
  ...
}:
{
  ren.aspects.svc-ai-hipfire.nixos =
    { host, pkgs, ... }:
    let
      cfg = host.svc-ai-hipfire;

      # Content-addressed acquisition: the model lands in the store and is
      # present the moment the closure is. No first-boot download step, and
      # nothing for the unit to race against.
      modelArtifact = pkgs.fetchurl {
        name = baseNameOf cfg.modelUrl;
        url = cfg.modelUrl;
        hash = cfg.modelHash;
      };

      draftArtifact =
        if cfg.draftUrl == null then
          null
        else
          lib.assertMsg "svc-ai-hipfire.draftHash is required when draftUrl is set" (cfg.draftHash != "") (
            pkgs.fetchurl {
              name = baseNameOf cfg.draftUrl;
              url = cfg.draftUrl;
              hash = cfg.draftHash;
            }
          );

      # Immutable store directory carrying the exact registry file names,
      # so the daemon's tag-to-file resolution finds the artifacts in
      # HIPFIRE_MODELS_DIR and uses them as-is (never re-downloading).
      modelStore = pkgs.symlinkJoin {
        name = "hipfire-models";
        paths = [ modelArtifact ] ++ lib.optionals (draftArtifact != null) [ draftArtifact ];
      };
    in
    {
      imports = [ inputs.hipfire.nixosModules.default ];

      services.hipfire = {
        enable = true;
        inherit (cfg)
          gpuTargets
          port
          openFirewall
          defaultModel
          temperature
          topP
          maxTokens
          maxSeq
          repeatPenalty
          kvCache
          dflashMode
          idleTimeout
          extraSettings
          perModelSettings
          environment
          userService
          user
          group
          ;
        # The store directory stands in for upstream's /var/lib/hipfire
        # models dir: its setup unit's `mkdir -p` is a no-op on the
        # existing store path, and the daemon reads it read-only.
        modelDir = modelStore;
      };
    };
}
