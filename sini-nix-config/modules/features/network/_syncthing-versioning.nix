# Append-only session logs (projects, ...) are immutable once written, so
# `staggered` hoards useless snapshots (GB-scale on receivers and the hub's
# aggregate). `trashcan` keeps the last replaced/deleted copy, which is all the
# delete-propagation protection they need. `memory` is small + curated: keep
# its edit history.
p:
if baseNameOf p == "memory" then
  {
    type = "staggered";
    params.maxAge = "2592000"; # 30 days
  }
else
  {
    type = "trashcan";
    params.cleanoutDays = "30";
  }
