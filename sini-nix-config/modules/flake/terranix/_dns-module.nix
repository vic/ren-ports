# Terraform body of the dns-records terranix module (cloudflare provider, encrypted local state).
{
  lib,
  zones,
  records,
  accounts,
  environment,
}:
let
  key = lib.replaceStrings [ "." "*" ] [ "_" "wildcard" ];
in
{
  terraform = {
    # The version is the nixpkgs provider's (terranix.nix), never stated here.
    required_providers.cloudflare.source = "cloudflare/cloudflare";
    backend.local.path = "terraform.tfstate";
    encryption = {
      key_provider.pbkdf2.state.passphrase = "\${var.state_passphrase}";
      method.aes_gcm.state.keys = "\${key_provider.pbkdf2.state}";
      state = {
        method = "method.aes_gcm.state"; # a bare reference, not an interpolation
        enforced = true;
      };
      plan = {
        method = "method.aes_gcm.state"; # a bare reference, not an interpolation
        enforced = true;
      };
    };
  };

  variable.state_passphrase = {
    type = "string";
    sensitive = true;
    description = "State and plan encryption passphrase (TF_VAR_state_passphrase)";
  };

  # Token from CLOUDFLARE_API_TOKEN.
  provider.cloudflare = { };

  data.cloudflare_zone = lib.listToAttrs (map (z: lib.nameValuePair (key z) { filter.name = z; }) zones);

  resource.cloudflare_dns_record = lib.mapAttrs (
    _: r:
    {
      zone_id = "\${data.cloudflare_zone.${key r.zone}.id}";
      inherit (r)
        name
        type
        content
        proxied
        ttl
        ;
    }
    // lib.filterAttrs (_: v: v != null) { inherit (r) priority comment; }
  ) records;

  # Read by the devshell commands: dns-adopt matches live records to
  # resource addresses; the account and environment select the secrets.
  _meta = {
    records = lib.mapAttrsToList (k: r: {
      address = "cloudflare_dns_record.${k}";
      inherit (r)
        name
        type
        content
        zone
        ;
    }) records;
    account = builtins.head accounts;
    environment = environment.name;
  };
}
