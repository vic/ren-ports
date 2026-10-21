# Cap every nix evaluation

Run every `nix eval`, `nix build`, `nix flake check`, nix-unit and
`nix develop ./ci --command ci` under a memory cap:

    systemd-run --user --scope -q -p MemoryMax=12G <command>

A regression can make any eval runaway, and the host is shared. Exit 137 under the cap
is a finding (a possible memory regression): report it with its command and never re-run
it uncapped.

In den-ag-design, heavy runs (suites, census, deps, perf-bench) also go through
`STATUS/heavy-lock.zsh <cmd>`, taken once per phase, never per command and never as a
private lock.
            '';
