# k3s server-only flag list (cluster CIDRs, etcd tuning, disabled built-ins, TLS SANs, OIDC via Kanidm).
{ ren, config, environment, cluster, v4, vip, peerTlsSans }:
let
  podNetwork = cluster.networks.kubernetes-pods;
  serviceNetwork = cluster.networks.kubernetes-services;
in
[
  "--bind-address=0.0.0.0"
  "--advertise-address=${v4}"
  "--cluster-cidr=${podNetwork.cidr},${podNetwork.ipv6_cidr}"
  "--service-cidr=${serviceNetwork.cidr},${serviceNetwork.ipv6_cidr}"
  "--kube-controller-manager-arg=--node-cidr-mask-size-ipv6=112"
  "--kubelet-arg=fail-swap-on=false"

  "--write-kubeconfig-mode \"0644\""
  "--kubelet-arg=--cluster-dns=${ren.helpers.getAssignment cluster "coredns"}"

  # etcd: 12h snapshots, 8GB quota, periodic compaction
  "--etcd-expose-metrics"
  "--etcd-snapshot-schedule-cron='0 */12 * * *'"
  "--etcd-arg=quota-backend-bytes=8589934592"
  "--etcd-arg=max-wals=5"
  "--etcd-arg=auto-compaction-mode=periodic"
  "--etcd-arg=auto-compaction-retention=30m"

  # Disable built-ins replaced by our stack
  "--disable metrics-server"
  "--disable local-storage"
  "--disable traefik"
  "--disable coredns"
  "--disable servicelb"
  "--flannel-backend=none"
  "--disable-network-policy"
  "--disable-kube-proxy"
  "--disable-cloud-controller"
  "--disable-helm-controller"

  # TLS SANs: API domain + FQDN + hostname + node IP + VIP
  "--tls-san=k8s.${environment.domain}"
  "--tls-san=${config.networking.fqdn}"
  "--tls-san=${config.networking.hostName}"
  "--tls-san=${config.networking.hostName}.ts.${environment.domain}"
  "--tls-san=${v4}"
  "--tls-san=${vip}"

  # OIDC via Kanidm
  "--kube-apiserver-arg=oidc-issuer-url=https://${ren.helpers.domainFor environment "kanidm"}/oauth2/openid/kubernetes"
  "--kube-apiserver-arg=oidc-client-id=kubernetes"
  "--kube-apiserver-arg=oidc-signing-algs=ES256"
  "--kube-apiserver-arg=oidc-username-claim=email"
  "--kube-apiserver-arg=oidc-groups-claim=groups"
]
++ peerTlsSans
