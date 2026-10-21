# The Bash tool runs zsh, not bash

Write zsh: quote every expansion, prefer arrays to word-splitting, use `${(P)var}`
for indirection or `bash -c '...'` where a bash idiom is genuinely wanted, and read
exit status unpiped (`cmd > file; echo $?`).

| bash idiom | in zsh | failure |
|---|---|---|
| `${!var}` | `${(P)var}` | loud: bad substitution |
| unquoted `$list` word-splits | stays one word | silent: every count, the control included, reads 0 |
| `$PIPESTATUS` | `$pipestatus` | silent empty |
| `shopt` | `setopt` | loud |
| `"$sha:lib/x"` | history modifier `:l` (also `:h :t :r :e :s`) eats the path; brace it, `"${sha}:lib/x"` | silent: wrong or empty output, exit 0 |
| a variable named `path` (or `cdpath`, `fpath`) | tied to `PATH`; assigning it removes every command | silent: `command not found` on stderr only |

A positive control that reads 0 has found a broken predicate, not an absence.
            '';
