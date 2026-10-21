# Volumes of the genie-guard pod.
let
  inherit (import ./_genie-guard-shared.nix) name;
in
[
  {
    name = "run";
    emptyDir.medium = "Memory";
  }
  {
    name = "state";
    emptyDir = { };
  }
  {
    name = "tmp";
    emptyDir = { };
  }
  {
    name = "tls";
    secret = {
      secretName = "${name}-xmsg-tls";
      defaultMode = 288; # 0440, read through fsGroup
    };
  }
  {
    name = "peers";
    configMap.name = "${name}-xmsg-peers";
  }
  {
    name = "api-key";
    secret = {
      secretName = name;
      items = [
        {
          key = "api-key";
          path = "api-key";
        }
      ];
      defaultMode = 288;
    };
  }
]
