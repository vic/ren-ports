# Static sites served from Garage website buckets.
#
# Each web.landing domain (the site-domains channel) gets a GarageBucket named
# after it (globalAlias = domain) with website mode on; Garage's web endpoint
# (:3902) picks the bucket from the Host header. The apex is routed to Garage on
# the domain's apex listener; www.<domain> 301s to the apex at the gateway.
#
# Content lives in nix-config/sites/<domain>/ and is published with the
# `publish-sites` devshell command, using the `sites-publisher` key (write on
# the site buckets only; its credentials Secret stays in the garage namespace).
{ lib, ... }:
let
  namespace = "garage";
  # k8s object names cannot contain dots.
  slug = lib.replaceStrings [ "." ] [ "-" ];
  clusterRef.name = "garage";
in
{
  ren.aspects.k8s-storage-garage-sites.k8s-manifests =
    { site-domains, ... }:
    let
      domains = map (s: s.domain) site-domains;
    in
    {
      applications.sites = {
        inherit namespace;

        objects =
          map (domain: {
            apiVersion = "garage.rajsingh.info/v1beta1";
            kind = "GarageBucket";
            metadata = {
              name = "site-${slug domain}";
              inherit namespace;
            };
            spec = {
              inherit clusterRef;
              globalAlias = domain;
              website = {
                enabled = true;
                indexDocument = "index.html";
                errorDocument = "404.html";
              };
            };
          }) domains
          ++ [
            {
              apiVersion = "garage.rajsingh.info/v1beta1";
              kind = "GarageKey";
              metadata = {
                name = "sites-publisher";
                inherit namespace;
              };
              spec = {
                inherit clusterRef;
                neverExpires = true;
                bucketPermissions = map (domain: {
                  bucketRef.name = "site-${slug domain}";
                  read = true;
                  write = true;
                }) domains;
                secretTemplate.name = "sites-publisher-credentials";
              };
            }
          ];
      };
    };
}
