# ccstatusline line 2: what it costs (sep = shared separator widget).
sep:
  # Line 2 — WHAT IT COSTS. The agent cap is quota-driven and model-tiered,
  # so the weekly Opus figure is a scheduling input, not trivia.
  [
    {
      type = "model";
      color = "cyan";
      rawValue = true;
    }
    {
      type = "thinking-effort";
      color = "brightBlack";
    }
    sep
    {
      type = "context-percentage";
      color = "green";
    }
    sep
    {
      type = "session-cost";
      color = "brightYellow";
    }
    {
      type = "session-usage";
      color = "brightBlue";
    }
    {
      # ★ `weekly-usage`, NOT `weekly-opus-usage`. Measured 2026-08-28 against
      # the live account: weekly-usage 70.0%, weekly-opus-usage 0.0%,
      # weekly-sonnet-usage 0.0%. There is no per-model weekly cap for this
      # account, so both per-model widgets report a limit that does not exist
      # and read a permanent, plausible-looking zero. The original choice was
      # reasoning from OUR agent cap being model-tiered — but that is a quota
      # policy we invented, not a limit the API reports.
      type = "weekly-usage";
      color = "brightMagenta";
      # `slider` is the only display mode that earns its width: a 10-block bar
      # AND the number. Measured — `progress` is 46 chars, `slider-only` drops
      # the number, and full-data/icon-* are no-ops that render exactly like the
      # default. Two sliders side by side make the BINDING constraint legible
      # without reading either figure.
      metadata.display = "slider";
    }
    {
      # ★ Fable has a REAL per-model weekly cap where Opus and Sonnet do not,
      # and on 2026-08-28 it was the tighter one: Fable 88.0% against overall
      # 70.0%. Showing only the overall figure hides the limit that actually
      # binds first.
      type = "fable-weekly-usage";
      color = "brightRed";
      metadata.display = "slider";
    }
  ]
