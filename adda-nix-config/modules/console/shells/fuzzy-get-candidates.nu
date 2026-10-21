# Shared candidate-fetch logic for nushell.nix's fuzzy_completion_menu (the Tab-triggered
# live completion menu) -- kept in its own file/module rather than inlined there so a fix to
# the merge logic only needs making once.
#
# Quote-aware argv-style split: a naive `split row ' '` breaks any earlier, already-typed
# argument containing a quoted space (e.g. `git commit -m 'fix bug' <cursor>`) into extra
# spans, which throws off both cmd0-position context and what carapace is asked to resolve.
# Quotes are stripped from the resulting words, matching how a real shell hands argv to a
# command -- carapace expects the same positional shape. An unterminated quote (still being
# typed) just runs to the end of the line as one word, same as a real shell would still be
# waiting on it. A trailing *unquoted* space gets an explicit trailing empty word appended --
# the convention completion engines (carapace included) rely on to tell "still completing the
# last word" apart from "about to type a new one after it": naive `split row ' '` does this
# for free as a side effect of how it splits, so it has to be done on purpose here instead.
export def split-shell-words [line: string] {
  mut tokens = []
  mut current = ""
  mut has_token = false
  mut in_squote = false
  mut in_dquote = false
  for ch in ($line | split chars) {
    if $in_squote {
      if $ch == "'" { $in_squote = false } else { $current = $current + $ch }
    } else if $in_dquote {
      if $ch == '"' { $in_dquote = false } else { $current = $current + $ch }
    } else if $ch == "'" {
      $in_squote = true
      $has_token = true
    } else if $ch == '"' {
      $in_dquote = true
      $has_token = true
    } else if $ch == ' ' {
      if $has_token {
        $tokens = ($tokens | append $current)
        $current = ""
        $has_token = false
      }
    } else {
      $current = $current + $ch
      $has_token = true
    }
  }
  if $has_token {
    $tokens = ($tokens | append $current)
  } else if (not ($tokens | is-empty)) and ($line | str ends-with ' ') {
    $tokens = ($tokens | append "")
  }
  $tokens
}

# `commandline complete -d` never invokes $env.config.completions.external.completer when
# given piped-string input (only nu's own structural/builtin completions, e.g. flags on
# builtins) -- for an *external* command's arguments (git, docker, ...) it silently returns
# nothing, which is most real-world completion. So for those, call both carapace and fish's
# completion engine directly and merge -- more comprehensive than either alone (fish's own
# resolver already merges its native completions with carapace's fish bridge; carapace
# called directly is a separate route through carapace's spec engine that doesn't go through
# fish's tsv conversion at all), and simpler/more consistent than replicating
# multiple_completers' git/nu/asdf-vs-carapace dispatch here.
export def get-candidates [before: string] {
  let spans = (split-shell-words $before)
  let cmd0 = ($spans | first | default "")
  # A plain `type == "external"` check misses `def --wrapped` commands that shadow a
  # same-named external (e.g. jj's own jjui wrapper): those resolve to "custom", so they'd
  # fall to the `commandline complete -d` branch below, which -- confirmed empirically for
  # such a wrapper -- gives nonsense (generic cwd file listings, and full history-line values
  # like "jj bookmark advance" instead of just "advance", since it has no real idea how to
  # complete a bare `[...args]` rest parameter). A builtin like `ls` also has a same-named
  # external on PATH, so checking "any external exists" alone would wrongly divert it too;
  # requiring the *first* (highest-precedence) match to be "custom" specifically targets
  # wrapper defs and leaves real builtins on their own (working) completion path.
  let is_arg_of_external = (
    ($spans | length) > 1
    and (try {
      let matches = (which -a $cmd0)
      let first_type = ($matches | first).type
      $first_type == "external" or ($first_type == "custom" and ($matches | any {|r| $r.type == "external"}))
    } catch { false })
  )

  if $is_arg_of_external {
    let carapace_result = (
      try {
        carapace $cmd0 nushell ...$spans
        | from json
        | default []
        # Carapace occasionally reports a resolution failure (e.g. an invalid git
        # object) as a single candidate literally named "<query>ERR" instead of
        # erroring or returning empty -- drop it rather than showing it as a match.
        | where value? != $"($spans | last)ERR"
        | each {|c|
            if ($c | describe) == "string" {
              { value: $c, description: "" }
            } else {
              { value: ($c.value? | default $c), description: ($c.description? | default "") }
            }
          }
      } catch { [] }
    )
    let fish_result = (
      try {
        # Not `from tsv`: fish emits some completions (plain filenames, generic
        # fallbacks) with no description column at all, which makes `from tsv
        # --flexible` produce rows of inconsistent shape -- some with a
        # description field, some without -- which then blows up as a
        # "column not found" error downstream (and, empirically, that specific
        # error isn't reliably caught by `try` here either). Splitting each line
        # by hand always yields the same {value, description} shape.
        #
        # --no-config: measured directly, plain `fish --command` here costs ~130ms almost
        # entirely from loading this repo's interactive fish config (functions,
        # interactiveShellInit, plugins) -- none of which this one-shot completion query
        # needs. --no-config cuts that to ~20ms with byte-for-byte identical output (verified:
        # diffed against the with-config run for both a jj and a git completion) since fish's
        # own completions -- man-page-derived, `wraps`-based, and git's dynamic
        # branch/commit/file lookups -- are function/completion *autoloading*, independent of
        # config.fish.
        fish --no-config --command $"complete '--do-complete=($before | str replace --all "'" "\\'")'"
        | lines
        | each {|line|
            let parts = ($line | split row (char tab))
            { value: ($parts | first), description: ($parts | get 1? | default "") }
          }
        | where value != ""
      } catch { [] }
    )
    $carapace_result | append $fish_result
  } else {
    try {
      # commandline complete -d's own result rows are inconsistently shaped -- some (e.g. a
      # builtin's own suggestion) carry a `description`, others (e.g. an external command
      # matched only by prefix) don't have that column at all. Normalize here, at the one
      # place all of get-candidates' callers already expect {value, description}, rather than
      # requiring every caller to guard the access itself.
      $before
      | commandline complete -d
      | default []
      | each {|c| { value: $c.value, description: ($c.description? | default "") } }
    } catch { [] }
  }
}
