# readme hosts (a fn of ren and lib): the Hosts section, one entry per `ren.host`, so the list cannot drift from the config.
{ ren, lib }:
let
  entries = map (host: {
    inherit (host) name description longDescription;
    system = host.system.name;
    dir = "modules/hosts/${host.name}";
  }) (builtins.attrValues ren.host);
in
''
  ## Hosts

  Each host is a `ren.host.<hostname>` instance in `modules/hosts/<hostname>/<hostname>.nix`, with an aspect `at` it.

  ${lib.concatMapStringsSep "\n" (
    {
      description,
      dir,
      longDescription,
      name,
      system,
    }:
    "- [`${name}`](${dir}) (`${system}`): ${description}"
    + lib.optionalString (longDescription != null) (
      "\n\n"
      + lib.concatMapStringsSep "\n" (line: if line == "" then "" else "  ${line}") (
        lib.splitString "\n" (lib.removeSuffix "\n" longDescription)
      )
      + "\n"
    )
  ) (lib.sortOn ({ name, ... }: name) entries)}

  Rebuild a host with `nh os switch --hostname <hostname>` (see `just host::switch`).
''
