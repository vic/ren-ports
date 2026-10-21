# Hindsight — agent memory engine: retain (LLM fact extraction) + recall
# (hybrid semantic/BM25/graph search) over per-bank Postgres+pgvector storage.
#
# The dataplane API only (`hindsight-api`, the image upstream's own chart
# deploys). The all-in-one `hindsight` image is not used: it bundles an embedded
# postgres and the Next.js control plane, and state belongs in hindsight-pg.
#
# The dataplane has no HTTPRoute. Reach it via the ClusterIP service, the
# internal LoadBalancer (hindsight-service.nix), or
# `kubectl -n ai port-forward svc/hindsight 8888`. The control-plane UI is served
# only at https://<domainFor "hindsight"> behind the gateway's kanidm OIDC, admins
# only (kanidm.nix `hindsight` client); nothing else reaches the CP pod.
#
# Auth. The dataplane reads `Authorization: Bearer <key>` into every request's
# context and runs it past two extension points: a TenantExtension (upstream ships
# ApiKeyTenantExtension, one key for every read and write on every bank, unused
# here) and an OperationValidatorExtension. This deployment loads one validator,
# _hindsight/hindsight-write-gate.py, configured from `gatedBanks`
# (_hindsight/shared.nix): each listed bank has its own token, which its writes
# need; a bank with gateReads needs it for reads too. Banks outside the list are
# open. The control plane holds an admin token the gate accepts on every listed
# bank; the dataplane holds only its SHA-256. Oracle:
# _hindsight/hindsight-write-gate-oracle.py, run against upstream's Python at the
# pinned version.
#
# Every gated route is a token check, document import included. Two routes call
# no validator hook at the pinned version — mental-model history (a read) and
# POST …/document-transfer into an existing bank (a write) — so the gate wraps
# MemoryEngine.get_mental_model_history and MemoryEngine.import_documents_async at
# runtime to call one. Those wrappers are of upstream methods: re-check both at
# every hindsight upgrade; startup fails if either method is gone. The network
# policies are source rules only (L3/L4), except tier-1's recall allow-list.
#
# Embeddings (BAAI/bge-small-en-v1.5) and reranking
# (cross-encoder/ms-marco-MiniLM-L-6-v2) run in-process on CPU at upstream
# defaults; both models are fetched from HuggingFace on first boot into the
# model-cache PVC, which is why this pod has world:443 egress.
#
# Keys are spread over hindsight-*.nix, all on this one aspect.
{ ren, ... }:
{
  ren.aspects.k8s-ai-hindsight = {
    # Hard dependency, not a coincidence of cluster composition: both LLM
    # endpoints and their model names are read out of llama-cpp's `instances`.
    includes = with ren.aspects; [ k8s-ai-llama-cpp ];

    service-domains = [ "hindsight" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "hindsight" ];

    k8s-manifests.applications.hindsight.namespace = "ai";
  };
}
