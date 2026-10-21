# Processes: kill and wait by PID

- Never `pkill -f`, `killall`, or `kill` on `pgrep -f` output. `-f` matches the full
  command line, and the shell running the command contains the pattern, so it matches
  itself and its parent (it has killed the orchestrator). Kill only PIDs you captured
  with `$!` at launch.
- Wait on a `$!` PID (`while kill -0 "$pid"`) or a marker the producer itself writes,
  always under `timeout` (`timeout 3600 zsh -c 'until …'`). Never `pgrep -f` from the
  waiting shell: it matches itself and never ends.
- A foreground command that hits the tool timeout moves to the background and keeps
  running. End your own waiters before starting new ones, and when a rebase kills the
  run they wait on.
            '';
