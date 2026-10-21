# HyperQwen (https://github.com/syv-ai/HyperQwen): a patched vLLM serving
# Qwen3.8-27B W4A16 on one 24 GB card, from upstream's prebuilt image.
#
# Every input is pinned here: the image by digest, the base checkpoint and the
# DFlash2 drafter file by file at a Hub revision, and so is every checkpoint in
# `models` (_hyperqwen-models.nix). The image is unpacked into a
# rootfs in the store and run with `podman --rootfs` (the guest mounts the
# host's store), so nothing is pulled into the guest's tmpfs root. The base
# checkpoint is copied once onto the hyperqwen share, where upstream's
# `prepare` requantizes it in place on first start (CPU, minutes).
#
# One engine per card: the unit conflicts with ninfer/llama-cpp/ollama and is
# started explicitly.
# Files: this (kind, secrets, firewall), hyperqwen-service.
{ ren, lib, ... }:
let
  inherit (import ./_hyperqwen-models.nix { inherit lib; }) models;
in
{
  ren.kinds.machine.svc-ai-hyperqwen = ren.lib.opt (lib.types.submodule {
    options = {
      port = lib.mkOption {
        type = ren.helpers.types.port;
        default = 18020;
        description = "Listen port.";
      };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          SPEC = "mtp";
        };
        description = ''
          Launcher knobs (single-user/start_qwen.sh): SPEC (mtp|dflash2),
          CTX (fast|long|huge), DFLASH_TOKENS, PREFIX_CACHE, MAX_LEN, ...
        '';
      };
      model = lib.mkOption {
        type = lib.types.enum (lib.attrNames models);
        default = "qwen3.8-27b";
        description = "The checkpoint served, by name from the catalogue at the top of this file.";
      };
      template = lib.mkOption {
        type = lib.types.enum [
          "stock"
          "froggeric"
        ];
        default = "stock";
        description = "`froggeric` serves froggeric/Qwen-Fixed-Chat-Templates v22.5 via `--chat-template`.";
      };
      autoStart = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Start at boot. Off: the unit conflicts with every other engine over the single GPU.";
      };
      clients = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Source addresses admitted to the port. Clients also need the API key (`hyperqwen/api-key.age` in the environment's secretPath).";
      };
    };
  }) { };

  ren.aspects.svc-ai-hyperqwen.nixos =
    {
      config,
      environment,
      host,
      ...
    }:
    let
      cfg = host.svc-ai-hyperqwen;
    in
    {
      # verify.sh refuses a network bind without a key. A consumer declares the same
      # rekeyFile and generator, so agenix-rekey gives it the same cleartext.
      age.secrets = {
        hyperqwen-api-key = {
          rekeyFile = environment.secretPath + "/hyperqwen/api-key.age";
          intermediary = true;
          generator.script = "hex";
        };
        hyperqwen-env = {
          generator.dependencies = [ config.age.secrets.hyperqwen-api-key ];
          settings.keys = [ "VLLM_API_KEY" ];
          generator.script = "environment-file";
        };
      };

      hardware.nvidia-container-toolkit.enable = true;
      virtualisation.podman.enable = true;

      networking.firewall.extraInputRules = lib.concatMapStrings (ip: ''
        ip saddr ${ip} tcp dport ${toString cfg.port} accept comment "hyperqwen"
      '') cfg.clients;
    };
}
