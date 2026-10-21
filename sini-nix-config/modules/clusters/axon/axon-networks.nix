# Axon networks. Fabric loopbacks 172.16.255.0/24 and fdfd:cafe:0:ff::/64 are reserved
# per host (axon-0N = .N/32, ::N/128), NOT networks entries.
{ ... }:
{
  ren.cluster.axon.networks = {
    control-plane = {
      cidr = "10.10.10.0/24";
      description = "Cluster control plane (VIP on management network)";
      assignments.kube-apiserver-vip = "10.10.10.100";
    };
    kubernetes-pods = {
      cidr = "172.20.0.0/16";
      ipv6_cidr = "fdfd:cafe:00:0001::/96";
      description = "Kubernetes pod network";
    };
    kubernetes-services = {
      cidr = "172.21.0.0/16";
      ipv6_cidr = "fdfd:cafe:00:8001::/112";
      description = "Kubernetes service network";
      assignments.coredns = "172.21.0.10";
    };
    kubernetes-loadbalancers = {
      cidr = "10.11.0.0/16";
      description = "LoadBalancer service IP range";
      assignments = {
        cilium-ingress-controller = "10.11.0.2";
        default-gateway = "10.11.0.1";
        # Internal-only LB for Shoko's API; BGP-advertised, NOT internet-routable.
        shoko-internal = "10.11.0.10";
        # ai stack .20-.29, private reach. .21 reserved (llama-cpp-qwen-internal
        # dropped), .23 reserved (hindsight-cp-internal dropped).
        hindsight-internal = "10.11.0.20";
        llama-cpp-gpt-oss-internal = "10.11.0.22";
        searxng-internal = "10.11.0.24";
        # Postfix relay to Proton, published as smtp.json64.dev.
        smtp-relay-internal = "10.11.0.30";
        # Host metrics/log push, published as ingest.json64.dev.
        monitoring-ingest = "10.11.0.31";
      };
    };
  };
}
