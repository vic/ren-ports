# synapse homeserver.yaml (ConfigMap) and data PVC.
{ ren, ... }:
let
  homeserver = cluster: {
    server_name = "json64.dev";
    public_baseurl = "https://${ren.helpers.clusterDomainFor cluster "matrix"}/";
    pid_file = "/data/homeserver.pid";
    listeners = [
      {
        port = 8008;
        tls = false;
        type = "http";
        x_forwarded = true;
        bind_addresses = [ "0.0.0.0" ];
        resources = [
          {
            names = [
              "client"
              "federation"
            ];
            compress = false;
          }
        ];
      }
    ];
    media_store_path = "/data/media_store";
    signing_key_path = "/secrets/signing.key";
    trusted_key_servers = [ { server_name = "matrix.org"; } ];
    suppress_key_server_warning = true;
    report_stats = false;
    max_upload_size = "50M";
    enable_registration = false;
    # New members join on their first login (MAS provisions through Synapse's
    # registration, which runs this). The room is local-only and created by
    # hand: Synapse autocreates only when the server's first user registers.
    auto_join_rooms = [ "#general:json64.dev" ];
    autocreate_auto_join_rooms = false;
    password_config.enabled = false;
    matrix_authentication_service = {
      enabled = true;
      endpoint = "http://matrix-authentication-service.matrix.svc.cluster.local:8080/";
      secret_path = "/secrets/mas-shared-secret";
    };
    # Sign in with a QR code. Both need MAS. msc4388 lets only a signed-in
    # device open a rendezvous.
    experimental_features = {
      msc4108_enabled = true;
      msc4388_mode = "authenticated";
    };
  };
in
{
  ren.aspects.k8s-communication-matrix-synapse.k8s-manifests =
    { cluster, ... }:
    {
      applications.synapse = {
        # The ConfigMap is not the chart's, so a change to it alone would not
        # roll the pod.
        helm.releases.synapse.values.controllers.main.pod.annotations."checksum/config" =
          builtins.hashString "sha256" (builtins.toJSON (homeserver cluster));

        resources = {
          configMaps.synapse-config.data."homeserver.yaml" = builtins.toJSON (homeserver cluster);

          persistentVolumeClaims.synapse-data.spec = {
            accessModes = [ "ReadWriteOnce" ];
            storageClassName = "longhorn";
            resources.requests.storage = "20Gi";
          };
        };
      };
    };
}
