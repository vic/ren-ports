# Shared bindings for the hindsight homeManager/homeLinux modules. Imported, not auto-loaded.
{ lib, pkgs, host, user, config }:
rec {
  cfg = host.dev-ai-mcp-hindsight;
  # The host's owner holds the bank's read-write token; every other user holds a
  # read-only token of their own (`readers` in k8s/ai/hindsight.nix),
  # so nothing that retains is installed for them.
  writer = user.name == host.system-owner.name;
  root = ../../../..;
  home = config.home.homeDirectory;
  jq = lib.getExe pkgs.jq;
  curl = lib.getExe pkgs.curl;
  flock = lib.getExe' pkgs.util-linux "flock";
  recall = "${home}/.claude/hindsight-recall.sh";
  archive = "${home}/.claude/hindsight-archive.sh";
  renderer = "${home}/.claude/hindsight-episode.jq";
  tokenFile = config.age.secrets.hindsight-token-den-law.path;

  # Template @name@ placeholders in the asset scripts (plain replace, bash `[@]` is untouched).
  fill = file: vars:
    lib.replaceStrings (map (n: "@${n}@") (lib.attrNames vars)) (lib.attrValues vars) (builtins.readFile file);
  common = {
    inherit jq curl tokenFile;
    endpoint = cfg.endpoint;
    bank = cfg.bank;
  };

  # Per-role recall inputs for the SubagentStart arm, keyed by agent role. Why the
  # role is read here rather than matched: the comment in hindsight-hooks-subagent.nix.
  subagentRecallInputs = lib.mapAttrs (role: q: {
    query = q;
    tags = [ "tier:law" "tier:trap" "role:${role}" ];
    tags_match = "any_strict";
    types = [ "world" "experience" ];
  }) {
    scout = "measurement law, absence claims and live controls, grep and predicate traps, tool behaviours that lie, burned control tokens, shell idioms that fail silently";
    gate = "adversarial gate rubric, prior art sweeps, refutation discipline, second independent pass, coordinate and citation checking";
    spec = "spec form and acceptance oracles, ADR law and amendment policy, owner rulings, forks that must not be settled by an agent";
    build = "landing and commit discipline, formatting before commit, nix-unit and oracle arming, seeded defects, push gates";
  };

  subagentRecall = pkgs.writeShellScript "hindsight-subagent-recall" (
    fill ./subagent-recall.sh (common // { inherit flock; inputs = lib.escapeShellArg (builtins.toJSON subagentRecallInputs); })
  );
}
