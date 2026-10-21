# Providers, variables, encrypted state and _meta of the unifi workspace.
{ environment, unifi }:
let
  api = "https://${environment.networks.default.gatewayIp}";
in
{
  terraform = {
    # Versions are the provider packages' (terraformWrapper), never stated here.
    required_providers = {
      unifi.source = "ubiquiti-community/unifi";
      # The gateway's custom NAT rules (v2 nat), which the unifi provider has no resource for.
      restapi.source = "Mastercard/restapi";
    };
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

  variable.unifi_api_key = {
    type = "string";
    sensitive = true;
    description = "The UniFi API key for the restapi provider (TF_VAR_unifi_api_key)";
  };

  variable.state_passphrase = {
    type = "string";
    sensitive = true;
    description = "State and plan encryption passphrase (TF_VAR_state_passphrase)";
  };

  # Key from UNIFI_API_KEY. The gateway serves a self-signed certificate.
  provider.unifi = {
    api_url = api;
    inherit (unifi) site;
    allow_insecure = true;
  };

  # The v2 API answers a write with the bare object, a list with a bare array.
  provider.restapi = {
    uri = "${api}/proxy/network";
    insecure = true;
    headers."X-API-KEY" = "\${var.unifi_api_key}";
    id_attribute = "_id";
    create_returns_object = true;
  };

  # Read by unifi-adopt.
  _meta = {
    api_url = api;
    inherit (unifi) site;
    bgp = "unifi_bgp.${environment.name}";
  };
}
