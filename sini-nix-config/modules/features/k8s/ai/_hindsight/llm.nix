# Resolves hindsight's LLM keys against the cluster fields declared by the
# llama-cpp instances and hindsight settings files.
{ lib, cluster }:
let
  settings = {
    defaultLlmInstance = cluster.k8s-ai-hindsight-settings-defaultLlmInstance;
    retainLlmInstance = cluster.k8s-ai-hindsight-settings-retainLlmInstance;
    externalLlms = cluster.k8s-ai-hindsight-settings-externalLlms;
  };

  # An LLM key resolves in one of two spaces: an in-cluster llama-cpp
  # instance, or an off-cluster endpoint declared in externalLlms. Model
  # identity stays defined once, at the endpoint that serves it.
  llamaInstances = cluster.k8s-ai-llama-cpp-settings-instances;
  externals = settings.externalLlms;

  # Fully qualified for the same reason the postgres DSN is; see the note
  # in hindsight-pg.nix on the short form failing to resolve here.
  resolve =
    key:
    if llamaInstances ? ${key} then
      {
        url = "http://llama-cpp-${key}.ai.svc.cluster.local:8080/v1";
        inherit (llamaInstances.${key}) modelAlias;
        external = null;
        # SERVING CAPACITY, derived rather than written down: llama-server
        # takes LLAMA_ARG_N_PARALLEL concurrent requests per pod, and the
        # ClusterIP service load-balances across the replicas. Anything past
        # this queues INSIDE llama-server, which is the one queue that costs
        # a timeout — see the backpressure block in env-backpressure.nix.
        slots = llamaInstances.${key}.replicas * llamaInstances.${key}.parallelSlots;
      }
    else if externals ? ${key} then
      {
        inherit (externals.${key}) url;
        modelAlias = externals.${key}.model;
        external = externals.${key};
        # An external endpoint's concurrency is not ours to know. null means
        # "do not cap from here" rather than a guessed number.
        slots = null;
      }
    else
      throw "hindsight: unknown LLM key '${key}' — llama-cpp instances: ${toString (builtins.attrNames llamaInstances)}; externalLlms: ${toString (builtins.attrNames externals)}";

  defaultLlm = resolve settings.defaultLlmInstance;
  retainLlm = resolve settings.retainLlmInstance;
in
{
  inherit settings defaultLlm retainLlm;

  # Egress rules only for the external endpoints actually in use. An
  # unreferenced externalLlms entry is a declaration, not a hole in the
  # policy.
  usedExternals = lib.filter (e: e != null) [
    defaultLlm.external
    retainLlm.external
  ];
}
