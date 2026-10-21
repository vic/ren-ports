# ai-omp: oh-my-pi (omp) agent through the LiteLLM proxy
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  # Every model goes through the LiteLLM proxy on mensa-nixos (modules/aspects/services/litellm.nix): CERIT-SC models
  #  under the `litellm` provider, Claude by re-pointing the built-in `anthropic` provider while it keeps its own OAuth
  #  login. The client holds no upstream provider key — only the proxy's virtual key, which is what the proxy
  #  authenticates; CERIT's key stays on the proxy and the Claude subscription token is passed through from the client.

  # Upstream force-moved tag v18.11.0, so the nixos-unstable recipe's src hash no longer matches
  # (hash mismatch in omp's `source`). Carries nixpkgs master's 18.11.2 until the channel catches up.
  ren.aspects.ai-omp.os =
    {
      user,
      ...
    }:
    {
      nixpkgs.overlays = [
        (final: prev: {
          omp = prev.omp.overrideAttrs (
            finalAttrs: _: {
              version = "18.11.2";
              src = final.fetchFromGitHub {
                owner = "can1357";
                repo = "oh-my-pi";
                tag = "v${finalAttrs.version}";
                hash = "sha256-PJbclp6GbOtIFkIVXQaJYlF63ArcqHgzlRLolrzXNDI=";
              };
              cargoDeps = final.rustPlatform.fetchCargoVendor {
                inherit (finalAttrs) src;
                hash = "sha256-2gnzA/DyvVHErgYoz8ORH29Oul1xxa2msH4/VAD3Aa4=";
              };
            }
          );
        })
      ];

      # The proxy needs a real virtual key now that it has a master key and a database, so clients can no longer send
      #  a placeholder. The key never enters a store path: `models.yml` references it as a `!cat` command (see the
      #  homeManager side), and this file is a runtime path only. `litellm-client.yaml` holds nothing but this key —
      #  `litellm.yaml` also carries the proxy's master and salt keys, which no client host may read.
      sops.secrets.litellmVirtualKey = {
        sopsFile = addax.secretsPath "litellm-client.yaml";
        key = "virtualKey";
        format = "yaml";
        owner = user.name;
      };
    };

  ren.aspects.ai-omp.homeManager =
    {
      fleet,
      config,
      lib,
      osConfig,
      pkgs,
      user,
      ...
    }:
    let
      # The proxy authenticates every model call with a LiteLLM virtual key. It is read at run time from the sops
      #  secret's path (`!cat …` is omp's command-backed config value, resolved and cached when a provider is used), so
      #  the key stays out of the world-readable store that `models.yml` is written to.
      litellmUrl = "https://litellm.${fleet.tailnet}";
      litellmKey = "!cat ${osConfig.sops.secrets.litellmVirtualKey.path}";

      # See:
      # https://omp.sh/docs/settings
      # https://github.com/can1357/oh-my-pi/blob/main/docs/settings.md
      # Three-file config layout ("profiles" without isolation):
      #   omp        <- sharedFile : anthropicFile
      #   omp-cerit  <- sharedFile : ceritFile
      # PI_CONFIG_FILES overlays deep-merge and later files win per leaf key, so
      # each variant file carries exactly the keys that must differ from the
      # shared base (provider selection + provider-specific retry behavior).
      # Keys declared only in shared settings stay shared; add an override to a
      # variant file to start diverging. Full session/auth/caches remain shared
      # (`omp --profile` would isolate them — not wanted here).
      sharedSettings = {
        tier = {
          anthropic = "none";
          subagent = "inherit";
        };
        personality = "default";
        defaultThinkingLevel = "auto";
        inlineToolDescriptors = "auto";
        # Provider-agnostic: when a provider reports usage-limit exhaustion WITH a
        # reset time, sleep until the reset instead of failing fast past maxDelayMs.
        # This is the last resort — the retry layer attempts a configured-fallback
        # model switch (the anthropic/* chain below) BEFORE reaching this, so it
        # never preempts the cerit fallback. Waits are abortable but hold subagents.
        retry.waitForUsageReset = true;
        # Web search: `web/public` first, then the rest. Declared with the modern keys
        # (`modelRoles.web` + `retry.fallbackChains.web`) instead of the legacy
        # `providers.webSearchOrder`: that key migrates to a chain which appends the built-in
        # Gemini trio `google-gemini-cli/gemini-2.5-flash`, `google-antigravity/...`,
        # `google/...`, and the gemini-cli variant has no native web search in the catalog, so
        # startup warns "Fallback chain for role 'web' does not resolve to a compatible model".
        modelRoles.web = "web/public";
        retry.fallbackChains.web = [
          "anthropic/claude-haiku-4-5"
          "web/parallel"
          "web/perplexity"
          "google-antigravity/gemini-2.5-flash"
          "google/gemini-2.5-flash"
          "openai-codex/gpt-6-luna"
          "openai-codex/gpt-5.6-luna"
          "openai-codex/gpt-5.6"
          "openai-codex/gpt-5.5"
          "openai/gpt-6-luna"
          "openai/gpt-5.6-luna"
          "xai/grok-4.5"
          "xai-oauth/grok-4.5"
          "web/zai"
          "web/exa"
          "web/tinyfish"
          "web/jina"
          "web/kagi"
          "web/tavily"
          "web/firecrawl"
          "web/brave"
          "web/kimi"
          "web/synthetic"
          "web/ollama"
          "web/searxng"
          "web/startpage"
          "web/duckduckgo"
          "web/ecosia"
          "web/google"
          "web/mojeek"
        ];

        # Appearance / TUI.
        symbolPreset = "nerd";
        theme = {
          dark = "dark-forest";
          light = "light";
        };
        composer.shape = "rule";
        hideThinkingBlock = false;
        showHardwareCursor = true;
        statusLine = {
          preset = "nerd";
          separator = "none";
          contextLine = "embedded";
          sessionAccent = true;
          transparent = true;
          compactThinkingLevel = false;
          showHookStatus = true;
        };
        tui = {
          resizeScrollback = "rebuild";
          textSizing = false;
          titleState = true;
          tight = false;
          imeSafeCursor = false;
        };
        terminal.showProgress = true;
        display = {
          showTokenUsage = false;
          showTurnTime = false;
          cacheMissMarker = false;
          hideToolActivity = true;
        };

        # Input / session handling.
        steeringMode = "all";
        followUpMode = "all";
        interruptMode = "wait";
        doubleEscapeAction = "tree";
        treeFilterMode = "default";
        autocompleteMaxVisible = 20;
        emojiAutocomplete = true;
        paste.largeMenuThreshold = 100;
        autoResume = false;
        error.notify = "off";
        recap.enabled = false;
        branchSummary.enabled = false;
        stt = {
          enabled = true;
          modelName = "parakeet";
          submitTrigger = "say-submit";
        };
        ttsr = {
          contextMode = "discard";
          repeatMode = "once";
        };
        startup = {
          showSplash = false;
          checkUpdate = false;
          changelogMode = "expanded";
        };
        update.channel = "stable";
        marketplace.autoUpdate = "notify";
        features.unexpectedStopDetection = "smart";

        # Subagents.
        task = {
          showResolvedModelBadge = true;
          eager = "default";
          enableEffort = true;
          # prewalk = true;
          maxEffort = "high";
          maxConcurrency = 8;
          isolation = {
            mode = "auto";
            merge = "patch";
            commits = "ai";
          };
        };
        # prewalk.enabled = true;
        # Reviewer agent: reads each primary turn, injects advice back. Same model in both
        # variants; `kimi` is CERIT's maintained alias for the latest Kimi (now K3, the
        # gateway's top Aider Polyglot scorer). Runs on the gateway, so it spends no
        # Anthropic quota.
        modelRoles.advisor = "litellm/cerit/kimi";
        # Backup reviewer while Kimi is down: `glm` (latest GLM, now 5.3) is the gateway's
        # second-best Aider Polyglot scorer. Not `coder`: CERIT's docs map it to
        # qwen3.8-flash-next while the live gateway serves glm-5.3 under it.
        retry.fallbackChains.advisor = [ "litellm/cerit/glm" ];
        advisor = {
          enabled = true;
          syncBacklog = "3";
        };

        # Memory / learning.
        memory.backend = "mnemopi";
        autolearn = {
          enabled = true;
          autoContinue = true;
          minToolCalls = 15;
        };
        mnemopi = {
          scoping = "global";
          enhancedRecall = true;
          polyphonicRecall = false;
          proactiveLinking = false;
          llmMode = "smol";
          injectionTokenLimit = 2500;
          recallLimit = 4;
          retainEveryNTurns = 8;
        };

        # Context management.
        compaction = {
          keepRecentTokens = 10000;
          v2RetainedMessageBudget = 32000;
          idleEnabled = true;
        };
        snapcompact.toolResults = true;

        # Tools.
        tools = {
          format = "auto";
          artifactSpillThreshold = 20;
          artifactTailLines = 150;
        };
        edit = {
          mode = "hashline";
          blackbox.enabled = false;
          autoRepair.enabled = true;
        };
        read = {
          renderMarkdown = true;
          toolResultPreview = true;
        };
        readLineNumbers = true;
        grep = {
          contextBefore = 1;
          contextAfter = 1;
        };
        lsp = {
          formatOnWrite = true;
          diagnosticsOnEdit = true;
        };
        eval = {
          autoBackground.enabled = true;
          jl = true;
          rb = true;
        };
        python.kernelMode = "session";
        bashInterceptor.enabled = false;
        shellMinimizer.sourceOutlineLevel = "aggressive";
        astGrep.enabled = true;
        checkpoint.enabled = true;
        github.enabled = true;
        # todo = {
        #   remindersMax = 5;
        #   eager = "default";
        # };
        images.urls.enabled = true;
        secrets.enabled = true;
        generate_image.enabled = false;
        computer.enabled = false;
        security.enabled = false;
        browser.enabled = false;
        exa.enabled = false;
      };

      sharedFile = pkgs.writers.writeYAML "omp-shared.yml" sharedSettings;

      # Anthropic variant (plain `omp`): roles pinned to the subscription, plus an
      # automatic fallback to the CERIT gateway when Anthropic usage credits are
      # exhausted. `retry.usageAwareFallback` reads Anthropic's coding-plan quota
      # reports and — at the reserve margin or a hard limit — switches to the
      # `anthropic/*` fallback chain below (usage-aware switching skips the error
      # round-trip; `retry.modelFallback` covers plain API failures). The chain is
      # keyed by the provider wildcard so it applies to every role that resolves to
      # an anthropic model, including subagents. NOTE: the whole subscription quota
      # is shared, so chain hops stay off Anthropic — cerit first, then alternates.
      anthropicFile = pkgs.writers.writeYAML "omp-anthropic.yml" {
        modelRoles = {
          default = "anthropic/claude-opus-5.5";
          smol = "anthropic/claude-haiku-4.5";
        };
        retry = {
          usageAwareFallback = true;
          fallbackChains = {
            # slow/plan roles resolve to the default role model, so there are no
            # role keys to add here — one wildcard covers them all.
            "anthropic/*" = [
              "litellm/cerit/kimi" # latest Kimi (now K3): strongest coding model on the gateway
              "litellm/cerit/coder" # second, *different* coding family (archetype alias)
            ];
          };
        };
      };

      # CERIT variant (`omp-cerit`): everything runs on the gateway. The
      # provider's model discovery registers every model the proxy lists
      # (`omp models litellm` to list; /model or `--models` to pick), these are
      # only the *role defaults* — kimi for coding, mini for cheap/fast,
      # thinker for reasoning (aliases per CERIT's docs).
      ceritFile = pkgs.writers.writeYAML "omp-cerit.yml" {
        modelRoles = {
          default = "litellm/cerit/kimi";
          smol = "litellm/cerit/mini";
          slow = "litellm/cerit/thinker";
          plan = "litellm/cerit/thinker";
        };
        # On the gateway there's no cheap-plane quota to protect; prefer being
        # told about failures instead of the tool silently waiting/switching.
        # (waitForUsageReset from the shared file still applies as a last resort.)
        retry.usageAwareFallback = false;
      };

      # Custom provider registry (`~/.omp/agent/models.yml`). OMP only reads this file — unlike
      # `config.yml` it is never rewritten at runtime — so a store symlink is safe here.
      # Schema: https://github.com/can1357/oh-my-pi/blob/main/docs/models.md
      modelsFile = pkgs.writers.writeYAML "omp-models.yml" {
        # CERIT-SC models (agentic, coder, mini, thinker, glm, ...:
        #  https://docs.cerit.io/en/docs/ai-as-a-service/llm-integration) as the proxy names them, `cerit/<id>`; omp
        #  ids are therefore `litellm/cerit/<id>`.
        providers.litellm = {
          baseUrl = "${litellmUrl}/v1";
          api = "openai-completions";
          apiKey = litellmKey;
          # Plain /v1/models listing (the proxy expands `cerit/*` from CERIT's own list). Not `litellm` discovery: it
          #  reads the proxy's /model_group/info, sees the `openai/*` backend that wildcard needs, and moves every
          #  model off chat completions onto the OpenAI Responses API.
          discovery.type = "openai-models-list";
        };
        # Override-only: the built-in Claude catalog and OAuth login stay as they are, only the host changes. The
        #  usage/quota probe behind retry.usageAwareFallback is not proxied; omp falls back to api.anthropic.com for it.
        #  The proxy key travels in its own header, not in `apiKey`, so `Authorization` keeps carrying the OAuth token:
        #  without `x-litellm-api-key` LiteLLM treats `Authorization` as its own key and strips the token
        #  (`clean_headers`) instead of forwarding it upstream.
        providers.anthropic = {
          baseUrl = litellmUrl;
          headers."x-litellm-api-key" = litellmKey;
        };
      };

      # `omp` gets `sharedFile:anthropicFile` via the session variable below;
      # `omp-cerit` appends `ceritFile` to whatever PI_CONFIG_FILES the session
      # had — later overlays deep-merge and win per leaf, so every role (and the
      # retry variance) flips to the gateway while shared settings stay in force.
      # Per-run switching also works without the wrapper:
      #   omp --model litellm/cerit/kimi   (single model, fuzzy matching)
      #   omp --config <ceritFile>      (same overlay, one run)
      #   /model inside the TUI         (session-scoped; the overlay re-pins roles next launch)
      ompCerit = pkgs.writeShellApplication {
        name = "omp-cerit";
        runtimeInputs = [ pkgs.omp ];
        text = ''
          PI_CONFIG_FILES="''${PI_CONFIG_FILES:+$PI_CONFIG_FILES:}${ceritFile}"
          export PI_CONFIG_FILES
          exec omp "$@"
        '';
      };

      # The shared standing instructions (modules/ai/_rules.nix) rendered into
      # OMP's native user rules directory, which it reads as `<name>.md` plus frontmatter.
      # `alwaysApply` keeps each body on every request instead of demoting the rule to an
      # on-demand rulebook entry the agent has to decide to load. Descriptions go through
      # `toJSON` because a bare YAML scalar cannot contain `: ` — JSON strings are valid YAML.
      ruleFiles = lib.mapAttrs' (
        name: rule:
        lib.nameValuePair ".omp/agent/rules/${name}.md" {
          source = pkgs.writeText "omp-rule-${name}.md" ''
            ---
            description: ${builtins.toJSON rule.description}
            alwaysApply: true
            ---

            ${rule.text}
          '';
        }
      ) user.aiRules;
    in
    {
      home.packages = [
        # (addax.omni pkgs).unified.llm-agents-nix.packages.omp
        pkgs.omp
        ompCerit
      ];

      home.file = ruleFiles // {
        ".omp/agent/models.yml".source = modelsFile;
        ".omp/agent/nix/shared.yml".source = sharedFile;
        ".omp/agent/nix/anthropic.yml".source = anthropicFile;
      };

      # OMP owns `~/.omp/agent/config.yml`: `/settings`, `omp config set` and ordinary runtime settings changes write
      # that file in place. Symlinking a store path there would make every one of those writes fail, so the declarative
      # settings are fed in as a `PI_CONFIG_FILES` overlay instead (loaded after the global file, before  --config`
      # overlays), which keeps the mutable file writable while making the values declared here authoritative.
      # Consequence: changing a key declared above from inside the TUI persists to `config.yml` but stays shadowed by
      # this overlay — change it here instead. Keys not declared above remain freely settable at runtime.
      # Stable home paths, not store paths: long-lived parents (zellij, terminals) keep the login-time value, and a
      # store path there would pin them to the settings of the generation they started under.
      home.sessionVariables.PI_CONFIG_FILES =
        lib.concatMapStringsSep ":" (name: "${config.home.homeDirectory}/.omp/agent/nix/${name}.yml")
          [
            "shared"
            "anthropic"
          ];
    };
}
