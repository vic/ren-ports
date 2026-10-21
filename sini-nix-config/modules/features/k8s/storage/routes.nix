# Public S3 exposure. Path-style on the shared *.json64.dev listener; vhost-style
# on the dedicated s3-json64-dev listener (the s3.json64.dev domain's resourceName).
# No OIDC SecurityPolicy - SigV4 key-auth is the gate.
#
# DNS: s3.json64.dev (this service-domain) and *.s3.json64.dev are DNS-only
# (grey-cloud) records in infra/dns, because proxied mode's 100 MB upload cap
# breaks S3 multipart.
{ ren, ... }:
{
  ren.aspects.k8s-storage-garage-routes = {
    service-domains = [ "garage-s3" ];
    served-domains =
      { cluster, ... }:
      ren.helpers.clusterServedDomains cluster {
        services = [ "garage-s3" ];
        proxied = false;
      };

    k8s-manifests =
      { cluster, ... }:
      {
        applications.garage.resources.httpRoutes = {
          # Path-style: s3.json64.dev rides the existing *.json64.dev wildcard listener.
          garage-s3-path.spec = {
            hostnames = [ (ren.helpers.clusterDomainFor cluster "garage-s3") ];
            parentRefs = [
              {
                name = "default-gateway";
                namespace = "gateways";
                sectionName = "${ren.helpers.domainForResource cluster "garage-s3"}-https";
              }
            ];
            rules = [
              {
                backendRefs = [
                  {
                    name = "garage";
                    port = 3900;
                  }
                ];
              }
            ];
          };

          # Vhost-style: *.s3.json64.dev on the dedicated s3-json64-dev listener.
          # s3Api.rootDomain = ".s3.json64.dev" makes Garage match the bucket from Host.
          garage-s3-vhost.spec = {
            hostnames = [ "*.${ren.helpers.clusterDomainFor cluster "garage-s3"}" ];
            parentRefs = [
              {
                name = "default-gateway";
                namespace = "gateways";
                sectionName = "s3-json64-dev-https";
              }
            ];
            rules = [
              {
                backendRefs = [
                  {
                    name = "garage";
                    port = 3900;
                  }
                ];
              }
            ];
          };
        };
      };
  };
}
