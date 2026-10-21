# hindsight-pg — CloudNativePG PostgreSQL cluster backing the hindsight bank.
#
# Its own cluster rather than a database on media-pg: the memory corpus is the
# fleet's law of record and should not share a failure domain with the media
# stack. Otherwise the coder-pg pattern — 2 instances on longhorn-single (CNPG
# owns redundancy via streaming replication), required anti-affinity, nightly
# volumeSnapshot backups to the NAS. hindsight consumes a single composed
# connection URL (hindsight-pg-dsn), the same shape coderd uses.
#
# The two extensions are created by postInitApplicationSQL rather than left to
# hindsight's own migrations: the `hindsight` role is the database owner, not a
# superuser. pgvector ships in the CNPG `standard`/`system` postgres images
# (the operator default here is ghcr.io/cloudnative-pg/postgresql:18.3-system-trixie);
# pg_trgm is contrib, used by hindsight's entity resolution.
#
# References the cluster-scoped `longhorn-snapshot` VolumeSnapshotClass declared
# by media-pg.nix.
#
# Keys are spread over hindsight-pg*.nix, all on this one aspect.
{ ... }:
{
  # Generated role password, rekeyed into the cluster sops store, plus the
  # composed DSN. The .age files are created by `agenix generate` after this
  # lands. template-file substitutes the password into a standalone URL so the
  # resulting sops value is a single ref that encrypts cleanly — a sopsRef
  # embedded mid-string cannot be resolved by the live-encryption.
  ren.aspects.k8s-ai-hindsight-pg.age-secrets =
    { environment, ... }:
    {
      imports = [
        ({ config, ... }: {
      age.secrets = {
        hindsight-pg-hindsight-password = {
          rekeyFile = environment.secretPath + "/hindsight-pg/hindsight-password.age";
          generator.script = "rfc3986-secret";
          sopsOutput = {
            file = "hindsight-pg";
            key = "hindsight";
          };
        };

        hindsight-pg-dsn = {
          rekeyFile = environment.secretPath + "/hindsight-pg/dsn.age";
          generator.script = "template-file";
          generator.dependencies = [ config.age.secrets.hindsight-pg-hindsight-password ];
          # Fully qualified on purpose. Measured from a pod in this namespace:
          # `hindsight-pg-rw.ai` gets NXDOMAIN, `hindsight-pg-rw.ai.svc.cluster.local`
          # returns the ClusterIP; hindsight's psycopg2 failed on the short form
          # with "could not translate host name" even with the primary Ready and
          # the -rw service carrying an endpoint.
              #
          # Why the short form fails here is NOT established. The obvious guess —
          # that `ai` collides with the real .ai TLD, so the Corefile's
          # `forward . 1.1.1.1` answers it authoritatively — does not survive its
          # control: `coder-pg-rw.coder` resolves exactly the same way (NXDOMAIN
          # queried absolutely) and coderd connects fine. So the FQDN is used
          # because it is the form measured to work, not because the mechanism is
          # understood. Don't shorten it back without re-measuring.
          settings.template = "postgresql://hindsight:%hindsight-pg-hindsight-password%@hindsight-pg-rw.ai.svc.cluster.local:5432/hindsight?sslmode=require";
          sopsOutput = {
            file = "hindsight-pg";
            key = "dsn";
          };
        };
      };
        })
      ];
    };
}
