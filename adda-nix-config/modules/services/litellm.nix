# services: litellm
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.services-litellm.nixos =
    {
      config,
      fleet,
      lib,
      pkgs,
      ...
    }:
    let
      hostName = "litellm.${fleet.tailnet}";
    in
    {
      # nixpkgs leaves litellm-proxy-extras unpackaged (FIXME in python-modules/litellm), but the proxy imports it as
      #  soon as database_url is set (prisma migrations/toolchain). It lives in litellm's own repo, so build it from
      #  the same src to keep the pinned `litellm-proxy-extras==` version in lockstep. Drop once nixpkgs packages it.
      nixpkgs.overlays = [
        (_final: prev: {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (pyFinal: pyPrev: {
              litellm-proxy-extras = pyFinal.buildPythonPackage {
                pname = "litellm-proxy-extras";
                version = "0.4.97";
                pyproject = true;
                inherit (pyPrev.litellm) src;
                sourceRoot = "${pyPrev.litellm.src.name}/litellm-proxy-extras";
                # Upstream pins uv_build exactly; any 0.11 builds it. dist/ holds stale prebuilt wheels that the
                #  install phase would install over ours.
                postPatch = ''
                  substituteInPlace pyproject.toml --replace-fail "uv_build==" "uv_build>="
                  rm -r dist
                '';
                build-system = [ pyFinal.uv-build ];
                pythonImportsCheck = [
                  "litellm_proxy_extras.utils"
                  "litellm_proxy_extras.prisma_toolchain"
                ];
                meta = {
                  description = "Prisma schema, migrations and toolchain for the LiteLLM proxy";
                  homepage = "https://github.com/BerriAI/litellm/tree/main/litellm-proxy-extras";
                  license = lib.licenses.mit;
                };
              };
              # prisma-client-py only becomes importable after `prisma generate` writes the client into its own package
              #  dir, which LiteLLM's Docker image does at build time and a read-only store never allows later. Generate
              #  it here against LiteLLM's schema, offline: nixpkgs' Prisma 6 CLI (via the python CLI's cache-dir
              #  layout) instead of the npm download of 5.17 that 0.15.0 pins, so its engine-version guard gets 6's.
              prisma = pyPrev.prisma.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  prev.nodejs
                  prev.jq
                ];
                # Platform detection shells out to a bare `openssl`, which the service has no PATH entry for.
                postPatch = (old.postPatch or "") + ''
                  substituteInPlace src/prisma/binaries/platform.py \
                    --replace-fail "['openssl'," "['${lib.getExe prev.openssl}',"
                '';
                postInstall = (old.postInstall or "") + ''
                  cache=$TMPDIR/prisma-cli
                  mkdir --parents $cache/node_modules
                  echo '{}' > $cache/package.json
                  ln --symbolic ${prev.prisma_6}/lib/prisma/packages/cli $cache/node_modules/prisma
                  HOME=$TMPDIR \
                  PATH=$out/bin:$PATH \
                  PYTHONPATH=$out/${pyFinal.python.sitePackages}:$PYTHONPATH \
                  PRISMA_BINARY_CACHE_DIR=$cache \
                  PRISMA_EXPECTED_ENGINE_VERSION=$(jq --raw-output \
                    '.dependencies."@prisma/engines-version" | split(".") | last' \
                    ${prev.prisma_6}/lib/prisma/packages/engines/package.json) \
                  PRISMA_SCHEMA_ENGINE_BINARY=${prev.prisma-engines_6}/bin/schema-engine \
                  PRISMA_QUERY_ENGINE_BINARY=${prev.prisma-engines_6}/bin/query-engine \
                  PRISMA_QUERY_ENGINE_LIBRARY=${prev.prisma-engines_6}/lib/libquery_engine.node \
                  CHECKPOINT_DISABLE=1 \
                    python -m prisma generate \
                      --schema ${pyPrev.litellm.src}/litellm-proxy-extras/litellm_proxy_extras/schema.prisma
                '';
                pythonImportsCheck = (old.pythonImportsCheck or [ ]) ++ [ "prisma.client" ];
              });
              litellm = pyPrev.litellm.overridePythonAttrs (old: {
                optional-dependencies = old.optional-dependencies // {
                  proxy = old.optional-dependencies.proxy ++ [ pyFinal.litellm-proxy-extras ];
                };
              });
            })
          ];
        })
      ];

      services.litellm = {
        enable = true;
        settings = {
          model_list = [
            # The CERIT-SC gateway (itself a LiteLLM proxy): `cerit/<id>` is forwarded as `<id>`, so every model the key
            #  can see is reachable without listing it here. CERIT serves the Anthropic Messages API natively, so
            #  /v1/messages (claude-cerit) is forwarded untranslated instead of being bridged to OpenAI's Responses API,
            #  which LiteLLM otherwise does for every `openai/` deployment.
            {
              model_name = "cerit/*";
              litellm_params = {
                model = "openai/*";
                api_base = "https://llm.ai.e-infra.cz/v1";
                api_key = "os.environ/CERIT_API_KEY";
              };
              model_info.supported_endpoints = [
                "/v1/chat/completions"
                "/v1/messages"
              ];
            }
            # Claude subscriptions: no api_key on purpose. LiteLLM forwards the caller's own `Authorization: Bearer
            #  sk-ant-oat…` OAuth token (Claude Code / omp login) upstream, so a request without one fails with 401
            #  instead of being billed to a shared key. https://docs.litellm.ai/docs/tutorials/claude_code_max_subscription
            # Only if the request also carries `x-litellm-api-key`: without it LiteLLM takes Authorization as its own
            #  proxy key and strips it (clean_headers in proxy/litellm_pre_call_utils.py).
            {
              model_name = "anthropic/*";
              litellm_params.model = "anthropic/*";
            }
          ];
          # Expand wildcard routes in /v1/models by asking the upstream instead of LiteLLM's bundled catalog, which knows
          #  nothing about CERIT's ids.
          litellm_settings.check_provider_endpoint = true;
          # With per-caller subscription tokens, one caller's expired token (401) would otherwise put the shared
          #  deployment into cooldown and fail everyone else's requests with 429.
          router_settings.disable_cooldowns = true;
          general_settings = {
            # Needed by virtual keys, spend logs and the SSO session cookie. The value itself is used for exactly
            #  two things here: encrypting database rows and acting as the fallback admin password on /ui. Model
            #  callers keep authenticating with the tailnet placeholder; caddy's tailscale_auth is still the real gate.
            master_key = "os.environ/LITELLM_MASTER_KEY";
            # SSO users, roles, budgets and /ui live in Postgres. Without it the login flow has nowhere to keep
            #  virtual keys or the SSO-mapped roles it would otherwise mint.
            database_url = "os.environ/LITELLM_DB_URL";
            # /ui sends users straight to tsidp instead of showing the username/password form first.
            auto_redirect_ui_login_to_sso = true;
          };
        };
        # No master_key: access control is the tailnet ACL (see the serviceDomain below), and LiteLLM only listens on
        #  127.0.0.1. Any key value is accepted, so clients send a placeholder `x-litellm-api-key`.
        # prisma's Path.home() can't resolve a home for a DynamicUser unit; point it at the state dir.
        environment = {
          HOME = config.services.litellm.stateDir;
          # nixpkgs' engine reports version 000…0, which the generated client's version guard rejects unless the
          #  binary is named explicitly. The same engine the client was generated against (prisma override above).
          PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines_6}/bin/query-engine";
          # Startup runs `prisma migrate deploy`. Plain `prisma` resolves to prisma-client-py's wrapper (litellm's own
          #  bin PATH puts it first), which npm-installs a CLI; offline mode takes nixpkgs' CLI, engines wired in.
          PRISMA_OFFLINE_MODE = "true";
          PRISMA_CLI_PATH = lib.getExe pkgs.prisma_6;
          # SSO redirect_uri base; LiteLLM reads it from the environment only (a general_settings key is ignored).
          #  Must match the redirect URI registered with tsidp below.
          PROXY_BASE_URL = "https://${hostName}";
        };
        environmentFile = config.sops.templates."litellm.env".path;
      };

      # Root-owned is fine: systemd reads EnvironmentFile before dropping to the DynamicUser.
      sops.secrets.litellm-cerit-api-key = {
        sopsFile = addax.secretsPath "cerit.yaml";
        key = "llmApiKey";
        format = "yaml";
      };
      sops.secrets.litellm-master-key = {
        sopsFile = addax.secretsPath "litellm.yaml";
        key = "masterKey";
        format = "yaml";
      };
      sops.secrets.litellm-salt-key = {
        sopsFile = addax.secretsPath "litellm.yaml";
        key = "saltKey";
        format = "yaml";
      };
      sops.secrets.litellm-sso-client-secret = {
        sopsFile = addax.secretsPath "litellm.yaml";
        key = "ssoClientSecret";
        format = "yaml";
        restartUnits = [ "tsidp.service" ];
      };
      sops.templates."litellm.env" = {
        content = ''
          CERIT_API_KEY=${config.sops.placeholder.litellm-cerit-api-key}
          LITELLM_MASTER_KEY=${config.sops.placeholder.litellm-master-key}
          LITELLM_SALT_KEY=${config.sops.placeholder.litellm-salt-key}
          LITELLM_DB_URL=postgresql://litellm@localhost/litellm?host=/run/postgresql
          GENERIC_CLIENT_ID=litellm
          GENERIC_CLIENT_SECRET=${config.sops.placeholder.litellm-sso-client-secret}
          GENERIC_AUTHORIZATION_ENDPOINT=https://idp.${fleet.tailnet}/authorize
          GENERIC_TOKEN_ENDPOINT=https://idp.${fleet.tailnet}/token
          GENERIC_USERINFO_ENDPOINT=https://idp.${fleet.tailnet}/userinfo
          GENERIC_SCOPE=openid email profile
        '';
        restartUnits = [ "litellm.service" ];
      };

      # tsidp only accepts clients from its own oidc-funnel-clients.json, normally filled by its UI or dynamic
      #  registration with generated ids. Upsert LiteLLM's entry before every start; other clients stay untouched.
      systemd.services.tsidp = {
        serviceConfig.LoadCredential = "litellm-client-secret:${config.sops.secrets.litellm-sso-client-secret.path}";
        preStart = ''
          clients=/var/lib/tsidp/oidc-funnel-clients.json
          [ -e "$clients" ] || echo '{}' > "$clients"
          ${lib.getExe pkgs.jq} \
            --rawfile secret "$CREDENTIALS_DIRECTORY/litellm-client-secret" \
            --arg uri "https://${hostName}/sso/callback" \
            '.litellm = {
              client_id: "litellm",
              client_secret: ($secret | rtrimstr("\n")),
              client_name: "LiteLLM",
              redirect_uris: [$uri],
              created_at: (.litellm.created_at // (now | todate))
            }' "$clients" > "$clients.new"
          chmod 600 "$clients.new"
          mv "$clients.new" "$clients"
        '';
      };

      # The /ui needs Postgres for SSO users and virtual keys. Peer auth over the local socket
      #  keeps credentials and traffic on the loopback; DynamicUser can't use peer auth, so login as
      #  litellm via password-less ident+trust on the Unix socket requires the OS user `litellm`.
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "litellm" ];
        ensureUsers = [
          {
            name = "litellm";
            ensureDBOwnership = true;
          }
        ];
      };
      # DynamicUser services get an ephemeral uid; peer auth maps that uid to `litellm` only if a real
      #  home~account exists. An ordinary system user is the simplest reliable shape.
      users.users.litellm = {
        isSystemUser = true;
        group = "litellm";
        home = config.services.litellm.stateDir;
      };
      users.groups.litellm = { };
      # Override the nixpkgs module: a real user for Postgres peer auth and a writable HOME. Prisma
      #  resolves Path.home() at import time, so HOME has to exist even before prisma data does.
      systemd.services.litellm.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "litellm";
        Group = "litellm";
        HOME = config.services.litellm.stateDir;
      };
    };

  ren.aspects.services-litellm.service-domains = { ... }: config: {
    subdomain = "litellm";
    # The work VMs (tag:work-server) must reach this one service, and tailscale_auth rejects every tagged node, so
    #  the gate here is the ACL alone: the node enrols as tag:llm (its own key, see the caddy aspect), and
    #  terraform/tailscale/config.nix grants tag:llm to Adda's devices and to tag:work-server, nothing else.
    tailscaleAuth = false;
    # Must hold a reusable, pre-approved auth key tagged tag:llm, in secrets/services-tailscale-tsauthkey.env.
    tailscaleAuthKeyEnv = "TS_AUTHKEY_LITELLM";
    extraConfig = /* caddyfile */ ''
      reverse_proxy ${config.services.litellm.host}:${toString config.services.litellm.port}
    '';
  };
}
