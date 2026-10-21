# Terraform body of the GitHub terranix workspace (Actions secret + variable per repo).
{
  lib,
  github,
  owner,
  repos,
  atticPublicKey,
}:
{
  terraform = {
    required_providers.github = {
      source = "integrations/github";
      inherit (github) version;
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
        method = "method.aes_gcm.state";
        enforced = true;
      };
    };
  };

  variable = {
    state_passphrase = {
      type = "string";
      sensitive = true;
      description = "State and plan encryption passphrase (TF_VAR_state_passphrase)";
    };
    attic_ci_push_token = {
      type = "string";
      sensitive = true;
      description = "The attic `ci` push token (TF_VAR_attic_ci_push_token)";
    };
  };

  # Token from GITHUB_TOKEN.
  provider.github = { inherit owner; };

  resource.github_actions_secret = lib.genAttrs repos (repository: {
    inherit repository;
    secret_name = "ATTIC_TOKEN";
    value = "\${var.attic_ci_push_token}";
  });

  resource.github_actions_variable = lib.genAttrs repos (repository: {
    inherit repository;
    variable_name = "ATTIC_PUBLIC_KEY";
    value = atticPublicKey;
  });
}
