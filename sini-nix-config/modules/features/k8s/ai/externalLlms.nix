# Hindsight setting, a cluster field: off-cluster OpenAI-compatible endpoints
# selectable by defaultLlmInstance / retainLlmInstance, in the same key space as
# the llama-cpp instances. Kept as explicit settings rather than derived from the
# ninfer-endpoints channel: that one is host-scoped, so reaching it would need a
# cluster-scoped collect crossing the dev/prod boundary for a single address —
# more machinery than the fact is worth, and it would hide the cross-environment
# dependency rather than state it.
#
# Each entry also carries the CIDR its egress policy needs: in-cluster traffic
# rides the clusterwide allow-internal-egress policy, but anything off-cluster
# must be named explicitly or Cilium's default-deny drops it.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
  llmT = t.submodule {
    options = {
      url = opt t.str null; # OpenAI-compatible base URL, including /v1.
      model = opt t.str null; # Model id the endpoint answers to: llama-cpp's --alias, not a label.
      cidr = opt t.str null; # Host CIDR for the egress CiliumNetworkPolicy.
      port = opt t.port null; # Port for the egress CiliumNetworkPolicy.
    };
  };
in
{
  ren.kinds.cluster.k8s-ai-hindsight-settings-externalLlms = opt (t.attrsOf llmT) {
    # Both entries are llama-cpp on cortex-cuda's ONE RTX 3090 Ti, which holds
    # a single engine at a time (ninfer is resident there and declares
    # Conflicts= over the card). ninfer itself is deliberately absent: it does
    # not implement the structured-output request shape hindsight sends (see
    # cortex-cuda below). cortex-cuda is bridged onto the dev LAN; the cluster
    # reaches it across the gateway's prod->dev firewall, which is not yet
    # declared for 8080 (ninfer's port is: gateway-policies).
    #
    # STANDING CAVEAT on both: this is a guest on a DEV-environment workstation
    # (roles.gaming, roles.dev-gui). Prod work pointed here queues behind
    # interactive use and stops when the machine reboots.

    # The standby engine (ninfer is resident; `systemctl start llama-cpp` on
    # the guest swaps it in), and the reason this host is worth pointing at: the
    # SAME gpt-oss-20b the in-cluster instances serve, under the SAME alias, so
    # selecting it changes which GPU answers rather than which model does.
    # reasoning_effort is pinned low server-side in services.ai.llama-cpp,
    # which is the retain-shaped setting — retain is prefill-bound extraction,
    # so thinking is latency that buys nothing.
    gpt-oss-cortex = {
      url = "http://10.9.2.2:8080/v1";
      model = "gpt-oss-20b";
      cidr = "10.9.2.2/32";
      port = 8080;
    };

    # Same host, same GPU, DIFFERENT SERVER. cortex-cuda now also runs
    # llama-cpp with gpt-oss-20b on 8080 beside ninfer on 8081.
    #
    # ★ THIS ONE CAN SERVE RETAIN AND ninfer CANNOT, for one reason: fact
    # extraction requests STRUCTURED OUTPUT. ninfer's request validator
    # rejects any non-text response_format by design — src/serve/
    # openai_schema.cpp:439 with tests/test_openai_schema.cpp asserting
    # "json response_format rejected" — so it is a code-level gap, not a
    # flag. llama-cpp constrains decoding to a schema, and both
    # json_schema and json_object return 200 here (measured 2026-09-02,
    # 1.8s for 4563 prompt tokens).
    #
    # Same MODEL as the in-cluster pool, so pointing retain here changes
    # WHERE extraction runs, never what the corpus was extracted by.
    cortex-cuda = {
      url = "http://10.9.2.2:8080/v1";
      model = "gpt-oss-20b";
      cidr = "10.9.2.2/32";
      port = 8080;
    };
  };
}
