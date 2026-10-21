# Garage static-site HTTPRoutes: apex -> Garage web (:3902); www -> 301 to apex.
# Same aspect as sites.nix.
{ ren, lib, ... }:
let
  slug = lib.replaceStrings [ "." ] [ "-" ];
in
{
  ren.aspects.k8s-storage-garage-sites.k8s-manifests =
    { site-domains, ... }:
    let
      domains = map (s: s.domain) site-domains;
    in
    {
      applications.sites = {
        resources.httpRoutes = lib.listToAttrs (
          lib.concatMap (domain: [
            (lib.nameValuePair "site-${slug domain}" {
              spec = {
                hostnames = [ domain ];
                parentRefs = [
                  {
                    name = "default-gateway";
                    namespace = "gateways";
                    sectionName = "${ren.helpers.resourceForDomain domain}-apex-https";
                  }
                ];
                rules = [
                  {
                    name = "site";
                    backendRefs = [
                      {
                        name = "garage";
                        port = 3902;
                      }
                    ];
                  }
                ];
              };
            })
            (lib.nameValuePair "site-${slug domain}-www" {
              spec = {
                hostnames = [ "www.${domain}" ];
                parentRefs = [
                  {
                    name = "default-gateway";
                    namespace = "gateways";
                    sectionName = "${ren.helpers.resourceForDomain domain}-https";
                  }
                ];
                rules = [
                  {
                    name = "to-apex";
                    filters = [
                      {
                        type = "RequestRedirect";
                        requestRedirect = {
                          hostname = domain;
                          scheme = "https";
                          statusCode = 301;
                        };
                      }
                    ];
                  }
                ];
              };
            })
          ]) domains
        );
      };
    };
}
