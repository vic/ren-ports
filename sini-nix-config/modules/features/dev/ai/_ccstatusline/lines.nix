# ccstatusline widget lines (see ccstatusline.nix).
lib:
let
  # `id` is required on every widget by ccstatusline's schema and carries no
  # meaning for a generated config, so it is derived from position rather than
  # hand-maintained. The TUI mints UUIDs; nothing reads them across saves that
  # we do not regenerate anyway.
  withIds = lib.imap0 (i: line: lib.imap0 (j: w: w // { id = "l${toString i}-${toString j}"; }) line);

  sep = {
    type = "separator";
    character = " · ";
    color = "brightBlack";
  };
in
withIds [
  (import ./line1.nix sep)
  (import ./line2.nix sep)
]
