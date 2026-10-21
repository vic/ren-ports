# genie-eval — the namespace genie-agent runs its untrusted Nix evals in, one
# Job per eval (xmsg/genie-agent-design.md §5.2, layers 3-4).
#
# The launcher identity lives in `matrix`, beside the genie-agent pod, and its
# only power is a Role here: create/get/list/watch/delete Jobs and read their
# pods and logs. Nothing in `matrix` (or any other namespace) is granted.
#
# Every container is bounded by the LimitRange (12Gi / 2 CPU, default limit and
# max) and requests its limit by default: Guaranteed QoS, so the scheduler
# reserves what an eval may use and four evals cannot burst a node past what it
# reserved. Four pods reserve 48Gi; that is the honest cost of the fence.
# The ResourceQuota caps the namespace at 4 live pods, so at most four evals run
# at once.
#
# Egress and ingress: genie-eval-net.nix. Gating check: genie-eval-check.nix.
_:
let
  launcher = {
    name = "genie-eval-launcher";
    namespace = "matrix";
  };
  bounds = {
    memory = "12Gi";
    cpu = "2";
  };
in
{
  ren.aspects.k8s-ai-genie-eval = {
    service-domains = [ ];

    k8s-manifests = { ... }: {
      applications.genie-eval = {
        namespace = "genie-eval";

        resources = {
          serviceAccounts.${launcher.name}.metadata = { inherit (launcher) namespace; };

          roles.${launcher.name}.rules = [
            {
              apiGroups = [ "batch" ];
              resources = [ "jobs" ];
              verbs = [
                "create"
                "get"
                "list"
                "watch"
                "delete"
              ];
            }
            {
              apiGroups = [ "" ];
              resources = [
                "pods"
                "pods/log"
              ];
              verbs = [
                "get"
                "list"
                "watch"
              ];
            }
          ];

          roleBindings.${launcher.name} = {
            roleRef = {
              apiGroup = "rbac.authorization.k8s.io";
              kind = "Role";
              inherit (launcher) name;
            };
            subjects = [
              {
                kind = "ServiceAccount";
                inherit (launcher) name namespace;
              }
            ];
          };

          limitRanges.genie-eval.spec.limits = [
            {
              type = "Container";
              default = bounds;
              defaultRequest = bounds;
              max = bounds;
            }
          ];

          resourceQuotas.genie-eval.spec.hard.pods = "4";
        };
      };
    };
  };
}
