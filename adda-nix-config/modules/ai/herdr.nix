# ai-herdr: tmux-like terminal multiplexer for AI coding agents
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.ai-herdr.homeManager = { pkgs, ... }: {
    # https://herdr.dev/: tmux-like terminal multiplexer for AI coding agents.
    #
    # Settings: `herdr --default-config`, see https://herdr.dev/docs/config-reference/).
    programs.herdr = {
      enable = true;
      package = (addax.omni pkgs).unified.llm-agents-nix.packages.herdr;

      settings = {
        # General.

        # Show first-run setup on startup. Missing or `true` shows onboarding;
        # kept `false` because the generated config is read-only, so herdr cannot
        # record onboarding completion itself.
        onboarding = false;

        #   # Server: virtual terminal used for layout and new panes while no client
        #   # is attached (an attached client is always authoritative).
        #   server = {
        #     headless_cols = 120; # > 0
        #     headless_rows = 40; # > 0
        #   };

        theme = {
          #     # catppuccin | terminal | tokyo-night | dracula | nord | gruvbox |
          #     # one-dark | solarized | kanagawa | rose-pine | vesper
          #     # (`terminal` follows the host terminal's ANSI palette).
          name = "drakula";

          #     # Follow the host terminal's light/dark appearance report. Manual theme
          #     # selection in Settings disables this.
          auto_switch = false;
          #     # Used by `auto_switch`; when omitted, herdr picks the built-in sibling
          #     # of `name` (e.g. tokyo-night/tokyo-night-day).
          #     dark_name = "catppuccin";
          #     light_name = "catppuccin-latte";

        };

        #   terminal = {
        #     # Executable (name or path, not a command line) for new interactive
        #     # panes. Empty means $SHELL, then /bin/sh.
        #     default_shell = "";
        #     # auto (login shells on macOS only) | login | non_login
        #     shell_mode = "auto";
        #     # follow (inherit source pane/workspace) | home | current
        #     # (herdr's process directory) | a fixed path such as "~/Projects".
        #     new_cwd = "follow";
        #   };

        #   # Nix installs ignore the preview channel and update via the package
        #   # manager; the background checks only phone home to herdr.dev.
        #   update = {
        #     channel = "stable"; # stable | preview
        #     version_check = true;
        #     manifest_check = true;
        #   };

        #   keys = {
        #     # Prefix key, e.g. "ctrl+b", "f12", "esc", "-".
        #     prefix = "ctrl+b";

        #     # Bindings are explicit: "prefix+n" needs the prefix first, "ctrl+alt+n"
        #     # is a direct terminal-mode chord. A value may also be a list when one
        #     # action needs several shortcuts, e.g. next_tab = [ "prefix+n" "ctrl+alt+]" ].
        #     # Empty string = unbound. Plain printable keys steal typing; prefer
        #     # "prefix+<key>" outside navigate mode.

        #     # Session / global.
        #     help = "prefix+?";
        #     settings = "prefix+s";
        #     detach = "prefix+q";
        #     reload_config = "prefix+shift+r";
        #     open_notification_target = "prefix+o";
        #     goto = "prefix+g";
        #     toggle_sidebar = "prefix+b";
        #     # Local-client-only: send a clipboard image to a remote session.
        #     remote_image_paste = "ctrl+v";

        #     # Workspaces (Spaces).
        #     workspace_picker = "prefix+w";
        #     new_workspace = "prefix+shift+n";
        #     rename_workspace = "prefix+shift+w";
        #     close_workspace = "prefix+shift+d";
        #     previous_workspace = "";
        #     next_workspace = "";
        #     switch_workspace = ""; # indexed, e.g. "prefix+shift+1..9"

        #     # Git worktrees.
        #     new_worktree = "prefix+shift+g";
        #     open_worktree = "";
        #     remove_worktree = ""; # asks for confirmation

        #     # Agents.
        #     previous_agent = "";
        #     next_agent = "";
        #     focus_agent = ""; # indexed, e.g. "prefix+alt+1..9"

        #     # Tabs.
        #     new_tab = "prefix+c";
        #     rename_tab = "prefix+shift+t";
        #     previous_tab = "prefix+p";
        #     next_tab = "prefix+n";
        #     move_tab_previous = ""; # e.g. "alt+shift+left"
        #     move_tab_next = ""; # e.g. "alt+shift+right"
        #     switch_tab = "prefix+1..9";
        #     close_tab = "prefix+shift+x";

        #     # Panes.
        #     rename_pane = "prefix+shift+p";
        #     edit_scrollback = "prefix+e"; # opens the scrollback in $EDITOR
        #     copy_mode = "prefix+[";
        #     focus_pane_left = "prefix+h";
        #     focus_pane_down = "prefix+j";
        #     focus_pane_up = "prefix+k";
        #     focus_pane_right = "prefix+l";
        #     swap_pane_left = "prefix+shift+h";
        #     swap_pane_down = "prefix+shift+j";
        #     swap_pane_up = "prefix+shift+k";
        #     swap_pane_right = "prefix+shift+l";
        #     cycle_pane_next = "prefix+tab";
        #     cycle_pane_previous = "prefix+shift+tab";
        #     last_pane = ""; # last focused pane across workspaces/tabs
        #     split_vertical = "prefix+v"; # side by side
        #     split_horizontal = "prefix+minus"; # stacked
        #     close_pane = "prefix+x";
        #     zoom = "prefix+z"; # legacy alias: fullscreen
        #     resize_mode = "prefix+r";
        #     resize_pane_left = ""; # e.g. "ctrl+shift+alt+left", skips resize mode
        #     resize_pane_down = "";
        #     resize_pane_up = "";
        #     resize_pane_right = "";

        #     # Navigate-mode movement only; these win while navigate mode is open and
        #     # may use plain keys. Must not use prefix+, esc, enter, tab, shift+tab,
        #     # left, right, or unmodified 1-9. Left/right arrows are permanent
        #     # aliases for pane-left/pane-right.
        #     navigate_workspace_up = "up";
        #     navigate_workspace_down = "down";
        #     navigate_pane_left = "h";
        #     navigate_pane_down = "j";
        #     navigate_pane_up = "k";
        #     navigate_pane_right = "l";

        #     # Custom command bindings. `type`: popup (session-modal, optional
        #     # `width`/`height` in cells or "80%") | pane (temporary zoomed pane) |
        #     # shell (detached) | plugin_action (installed plugin action id).
        #     # `description` replaces the 'custom command' label in `prefix+?`.
        #     # command = [
        #     #   {
        #     #     key = "prefix+alt+g";
        #     #     type = "popup";
        #     #     command = "lazygit";
        #     #     description = "run lazygit";
        #     #     width = "80%";
        #     #     height = "80%";
        #     #   }
        #     #   {
        #     #     key = "prefix+t";
        #     #     type = "popup";
        #     #     command = "exec \"$SHELL\"";
        #     #     description = "open scratch terminal";
        #     #   }
        #     # ];

        #     # Legacy indexed shortcuts, still parsed; prefer switch_tab,
        #     # switch_workspace and focus_agent above.
        #     indexed = {
        #       tabs = ""; # e.g. "ctrl" for ctrl+1..9
        #       workspaces = ""; # e.g. "ctrl+shift"
        #       agents = ""; # e.g. "alt"
        #     };
        #   };

        ui = {
          #     # Sidebar geometry (columns); width auto-scales from workspace names.
          #     sidebar_width = 26;
          #     sidebar_min_width = 18;
          #     sidebar_max_width = 36;
          #     sidebar_start_collapsed = false; # takes effect on next launch
          #     sidebar_collapsed_mode = "compact"; # compact (status rail) | hidden
          #     # Terminal width at or below which the mobile single-column layout is used.
          #     mobile_width_threshold = 64;

          #     # Mouse and cursor.
          #     mouse_capture = true; # false lets the terminal handle clicks/URLs
          #     copy_on_select = true; # false retains the selection until Ctrl+C
          #     host_cursor = "auto"; # auto | native | drawn
          #     # Modifier forwarding right-click gestures to pane apps; empty disables.
          #     # ctrl | alt | cmd | super | meta | hyper (or a + combination); shift rejected.
          #     right_click_passthrough_modifier = "";
          #     redraw_on_focus_gained = true;
          #     mouse_scroll_lines = 3;

          #     # Prompts.
          #     confirm_close = true; # confirm before closing a workspace
          #     prompt_new_tab_name = true;
          #     prompt_new_workspace_name = false;

          #     # Pane chrome.
          #     pane_borders = true;
          #     pane_outer_borders = true;
          #     pane_scrollbars = true;
          #     pane_gaps = true;
          show_agent_labels_on_pane_borders = true;

          #     # Tab row.
          #     hide_tab_bar_when_single_tab = false;
          #     tab_bar_position = "top"; # top | bottom
          #     # Ordered right-aligned status entries. Types: zoom | hostname |
          #     # datetime (strftime `format`, no %z/%s) | text (`text`) | command
          #     # (`command`, `interval_seconds` 1..31536000, `timeout_seconds` 1..3600).
          #     # hostname/datetime/command resolve on the server, so `--remote` shows
          #     # the remote machine.
          #     tab_bar_right = [
          #       # { type = "zoom"; }
          #       # { type = "hostname"; }
          #       # { type = "datetime"; format = "%H:%M"; }
          #       # { type = "text"; text = "prod"; }
          #       # {
          #       #   type = "command";
          #       #   command = "~/.config/herdr/status.sh";
          #       #   interval_seconds = 5;
          #       #   timeout_seconds = 2;
          #       # }
          #     ];
          #     tab_bar_right_separator = " "; # "" concatenates directly

          #     # Title herdr writes to its outer terminal. Tokens: {hostname},
          #     # {workspace}, {tab}, {pane}, {terminal_title}; {{ }} are literal braces.
          #     # "" leaves the outer title alone.
          #     window_title = "{hostname}: {workspace}";

          #     agent_panel_sort = "spaces"; # spaces (grouped) | priority (attention queue)
          #     status_indicators = "dots"; # dots | symbols (static, no spinner)
          #     # Accent for highlights, borders and navigation UI: hex, named color, or rgb().
          #     accent = "cyan";

          #     sidebar = {
          #       # Each inner list is one rendered line; at most 16 rows of 16 tokens.
          #       # A token may be an inline style table:
          #       #   { token = "workspace"; fg = "#89b4fa"; bold = true; dim = false; }
          #       # (`fg` strictly #RGB/#RRGGBB; omitted fields keep contextual styling).
          #       agents = {
          #         row_gap = 0; # 1 restores the pre-0.8 spacing
          #         # Tokens: state_icon | state_text | workspace | tab | pane | agent |
          #         # terminal_title | terminal_title_stripped | $name (pane metadata
          #         # from `herdr pane report-metadata`).
          #         rows = [
          #           [
          #             "state_icon"
          #             "workspace"
          #             "tab"
          #           ]
          #           [ "agent" ]
          #         ];
          #         # Full replacements (not extensions) keyed by canonical agent id
          #         # (claude, codex, pi, ...); detection aliases are rejected.
          #         # rows_by_agent = {
          #         #   claude = [
          #         #     [ "state_icon" "agent" "state_text" ]
          #         #     [ "terminal_title_stripped" ]
          #         #     [ "workspace" "tab" ]
          #         #   ];
          #         # };
          #       };
          #       spaces = {
          #         row_gap = 0;
          #         # Tokens: state_icon | state_text | workspace | branch | git_status |
          #         # $name (workspace metadata from `herdr workspace report-metadata`).
          #         rows = [
          #           [
          #             "state_icon"
          #             "workspace"
          #           ]
          #           [
          #             "branch"
          #             "git_status"
          #           ]
          #         ];
          #       };
          #     };

          #     # Popup notifications for agents that finish or need input; popups for
          #     # the active tab are always suppressed.
          toast = {
            #       # off | herdr (in-app toast) | terminal (outer terminal, works over
            #       # SSH) | system (OS notification service)
            delivery = "system";
            #       delay_seconds = 1; # 0..3600; notifies only if the state still holds
            #       herdr.position = "bottom-right"; # top-left | top-right | bottom-left | bottom-right
            #       clipboard = {
            #         enabled = true; # copied-to-clipboard popup after a mouse copy
            #         # top-left | top-center | top-right | bottom-left | bottom-center | bottom-right
            #         position = "bottom-center";
            #       };
          };

          #     # Sounds play through the local client; $HERDR_DISABLE_SOUND overrides
          #     # `enabled`. Custom sounds must be mp3; relative paths resolve from the
          #     # config file's directory (i.e. the store path) — use absolute paths.
          #     sound = {
          #       enabled = true;
          #       # path = "/home/adda/.local/share/herdr/notification.mp3"; # all sounds
          #       # done_path = "/home/adda/.local/share/herdr/done.mp3"; # finished only
          #       # request_path = "/home/adda/.local/share/herdr/request.mp3"; # needs-input only

          #       # Per detected agent: default | on | off.
          #       agents = {
          #         pi = "default";
          #         claude = "default";
          #         codex = "default";
          #         gemini = "default";
          #         cursor = "default";
          #         devin = "default";
          #         agy = "default";
          #         cline = "default";
          #         open_code = "default";
          #         github_copilot = "default";
          #         kimi = "default";
          #         kiro = "default";
          #         droid = "off"; # muted upstream by default
          #         amp = "default";
          #         grok = "default";
          #         hermes = "default";
          #         kilo = "default";
          #         qodercli = "default";
          #         qwen = "default";
          #         maki = "default";
          #       };
          #     };
        };

        #   # Resume supported agent panes into their native conversations after a
        #   # server restart (needs an official integration reporting a session ref).
        #   session.resume_agents_on_restore = true;

        #   # Root for sidebar-created worktree checkouts: <directory>/<repo>/<branch-slug>.
        #   worktrees.directory = "~/.herdr/worktrees";

        #   # `herdr --remote` runs SSH through a generated config that includes the
        #   # user/system configs first and only adds keepalive fallbacks plus a
        #   # private control socket. false runs plain ssh unchanged.
        #   remote.manage_ssh_config = true;

        #   # Scrollback retained per pane, in bytes (legacy alias: scrollback_lines).
        #   advanced.scrollback_limit_bytes = 10000000;

        experimental = {
          allow_nested = true; # launch herdr inside a herdr pane
          kitty_graphics = true; # needs a Kitty-graphics-capable outer terminal
          #     # Persist pane screen contents to session-history.json; see
          #     # https://herdr.dev/docs/session-state/ for the security trade-off.
          #     pane_history = false;
          #     # macOS/Windows only: keep IME candidate windows anchored in panes whose
          #     # TUI hides the hardware cursor. Trade-off: an extra visible cursor in
          #     # apps that hide it without painting one (vim normal mode).
          #     reveal_hidden_cursor_for_cjk_ime = false;
          #     # Restrict the reveal to these detected agents; empty means any pane.
          #     # Accepted: pi, claude, codex, gemini, cursor, devin, cline, opencode,
          #     # copilot, kimi, kiro, droid, amp, grok, hermes, kilo, qodercli, qoder,
          #     # qwen, qwen-code, maki.
          #     cjk_ime_agents = [ ];
          #     # block | steady_block | underline | steady_underline | bar | steady_bar
          #     cjk_ime_cursor_shape = "steady_block";
          #     # macOS/Windows only: switch to an ASCII-capable input source while
          #     # prefix mode is active, then restore it.
          #     switch_ascii_input_source_in_prefix = false;
        };
      };
    };
  };
}
