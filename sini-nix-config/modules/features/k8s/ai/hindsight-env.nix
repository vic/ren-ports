# hindsight dataplane env, composed from the _hindsight/env*.nix assets. The
# retain override is emitted ONLY when retainLlmInstance differs from the default.
{ lib, ... }:
let
  shared = import ./_hindsight/shared.nix { inherit lib; };
in
{
  ren.aspects.k8s-ai-hindsight.k8s-manifests =
    { cluster, ... }:
    let
      llm = import ./_hindsight/llm.nix { inherit lib cluster; };
      split = llm.settings.retainLlmInstance != llm.settings.defaultLlmInstance;
    in
    {
      applications.hindsight.helm.releases.hindsight.values.controllers.main.containers.main.env =
        import ./_hindsight/env.nix { inherit shared llm; }
        // import ./_hindsight/env-backpressure.nix { inherit llm; }
        // import ./_hindsight/env-gate.nix { inherit lib shared; }
        // lib.optionalAttrs split (import ./_hindsight/env-retain.nix { inherit llm; });
    };
}
