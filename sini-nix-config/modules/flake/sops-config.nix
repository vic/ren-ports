# .sops.yaml: master recipients for *.enc.yaml, plus one creation rule per cluster with an age recipient.
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
  # Master identity .pub files carry a comment line "# Recipient: age1...".
  extractRecipient =
    pubFile:
    let
      lines = lib.splitString "\n" (builtins.readFile pubFile);
      hits = builtins.filter (l: lib.hasPrefix "#" l && lib.hasInfix "Recipient:" l) lines;
    in
    if hits != [ ] then lib.trim (lib.last (lib.splitString "Recipient: " (builtins.head hits))) else null;

  clusterRule =
    cluster: key: {
      path_regex = ".*${lib.escapeRegex key}.*/(SopsS|S)ecret-.*\\.ya?ml$";
      encrypted_regex = "^(data|stringData)$";
      mac-only-encrypted = true;
      key_groups = [ { age = [ (ren.helpers.sopsAgeRecipient cluster) ]; } ];
    };
in
{
  ren.aspects.sops-config = {
    at = ren.kinds.fleet;
    files =
      { pkgs, fleet, ... }:
      let
        masters = lib.unique (
          builtins.filter (r: r != null) (map extractRecipient fleet.secretsConfig.masterIdentities)
        );
        clusters = lib.filterAttrs (_: c: ren.helpers.sopsAgeRecipient c != null) ren.cluster;
        sopsConfig.creation_rules = [
          {
            path_regex = ".*\\.enc\\.ya?ml$";
            key_groups = [ { age = masters; } ];
          }
        ]
        ++ lib.mapAttrsToList (n: c: clusterRule c "${c.environment.name}-${n}") clusters;
      in
      {
        files.files = [
          {
            path_ = ".sops.yaml";
            drv = pkgs.runCommand ".sops.yaml" {
              nativeBuildInputs = [ pkgs.yq ];
              json = builtins.toJSON sopsConfig;
              passAsFile = [ "json" ];
            } ''yq -y '.' "$jsonPath" > $out'';
          }
        ];
      }; # files module shape: sini/files module.nix `files.files` list ({ path_ = alias of path; drv }), pkgs from specialArgs (flake/_files-eval.nix)
  };
}
