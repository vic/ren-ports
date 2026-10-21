# llama.cpp servers on the axon APUs — OpenAI-compatible inference in-cluster.
#
# The nodes are Ryzen 9 7940HS / Radeon 780M (gfx1103, RDNA3, 12 CU) with
# 2x32 GB DDR5-5600. GPU access needs no new plumbing: the ROCm device plugin
# (hardware.amd-gpu-device-plugin) already advertises `amd.com/gpu: 1` on every
# node, and its Allocate injects /dev/kfd AND /dev/dri/card+renderD — so a pod
# requesting that resource gets the render node Vulkan needs.
#
# Vulkan, not ROCm: gfx1103 is absent from the upstream ROCm image's
# AMDGPU_TARGETS, so that route needs an HSA_OVERRIDE_GFX_VERSION masquerade as
# gfx1102. RADV has no such gap.
#
# On an APU the GPU buys PREFILL, not decode. Decode is bandwidth-bound and the
# iGPU shares the CPU's bus — 89.6 GB/s theoretical — so what matters is bytes
# read per token, which is why both models here are MoE. The APU's compensating
# advantage is CAPACITY: 62 GB of addressable RAM holds models a 24 GB discrete
# card cannot, at full context.
#
# Every pod is pinned to its own node by the exclusive amd.com/gpu allocation —
# no anti-affinity needed — so the fleet-wide budget is
# `sum over instances of replicas <= schedulable GPU nodes`. Nothing enforces
# that: an over-budget pod sits Pending rather than failing at eval.
#
# Scaling is horizontal, and deliberately so (measured 780M aggregate: 23.5
# tok/s at 1 request, 32.4 at 2, 40.5 at 4). NOT the answer here: llama.cpp's
# RPC backend, which tensor-splits one model across hosts — it makes a single
# request slower, and these models already fit.
#
# Cluster-internal only: http://llama-cpp-<name>.ai.svc:8080/v1.
# Network policies: llama-cpp-net.nix. Instances: instances.nix.
{ ren, lib, ... }:
let
  shared = import ./_llama-cpp-shared.nix;
  inherit (shared) port;
in
{
  ren.aspects.k8s-ai-llama-cpp.k8s-manifests =
    {
      cluster,
      charts,
      images,
      ...
    }:
    let
      container = import ./_llama-cpp-container.nix { inherit shared images; };

      mkRelease = name: inst: {
        chart = charts.bjw-s-labs.app-template;
        values = {
          controllers.main = container inst;

          service.main = {
            controller = "main";
            # Pin the in-cluster name to `llama-cpp-<key>`: bjw-s suffixes every
            # service with its identifier once a controller owns >1 service
            # (main would become `llama-cpp-qwen-main`), which would dangle
            # hindsight's HINDSIGHT_API_*_LLM_BASE_URL.
            forceRename = "llama-cpp-${name}";
            ports.http.port = port;
          };

          # Private-network reach on a kubernetes-loadbalancers address, the
          # shoko idiom: BGP-advertised to the LAN, not internet-routable. The
          # assignment name derives from the instance key, so an instance
          # without a reserved address fails at eval rather than coming up
          # unreachable.
          #
          # NOTE: llama-server runs with no API key, so anything on the LAN that
          # can route here can spend GPU time. The CiliumNetworkPolicy is the
          # only control.
          service.internal = {
            controller = "main";
            type = "LoadBalancer";
            externalTrafficPolicy = "Local";
            annotations."lbipam.cilium.io/ips" =
              ren.helpers.getAssignment cluster "llama-cpp-${name}-internal";
            ports.http.port = port;
          };
        };
      };
    in
    {
      applications.llama-cpp = {
        namespace = "ai";

        helm.releases = lib.mapAttrs' (
          name: inst: lib.nameValuePair "llama-cpp-${name}" (mkRelease name inst)
        ) cluster.k8s-ai-llama-cpp-settings-instances;
      };
    };
}
