# xremap: key remapper for KDE (uinput), service per user
{ ren, inputs, ... }:
{
  ren.aspects.xremap.os = { user, ... }: {
    # imports = [ inputs.omniflake.unified.xremap.nixosModules.default ];
    imports = [ inputs.xremap.nixosModules.default ];

    # xremap grabs the keyboard and replays events through /dev/uinput, so the node has to exist and be group-writable.
    hardware.uinput.enable = true;

    services.xremap = {
      enable = true;
      withKDE = true;
      serviceMode = "user";
      userName = user.name; # xremap option name
      watch = true;
      mouse = false;
      #deviceNames = [];
      #extraArgs = [];
      config = {
        # https://github.com/emberian/evdev/blob/1d020f11b283b0648427a2844b6b980f1a268221/src/scancodes.rs#L26-L572

        default_mode = "default";

        virtual_modifiers = [
          "KEY_UNKNOWN"
          "KEY_ZENKAKUHANKAKU"
          "KEY_HIRAGANA"
          "KEY_RESERVED"
          "KEY_KATAKANAHIRAGANA"
          "KEY_FINANCE"
        ];

        modmap = [
          {
            remap = {
              # Modifier keys.
              KEY_SPACE = {
                held = "KEY_UNKNOWN";
                alone = "KEY_SPACE";
                free_hold = true;
                #alone_timeout_millis: 250
              };
              KEY_F = {
                held = "KEY_ZENKAKUHANKAKU";
                alone = "KEY_F";
                free_hold = true;
                #alone_timeout_millis: 250
              };
              KEY_D = {
                held = "KEY_HIRAGANA";
                alone = "KEY_D";
                free_hold = true;
                #alone_timeout_millis: 250
              };
              KEY_C = {
                held = "KEY_RESERVED";
                alone = "KEY_C";
                free_hold = true;
                #alone_timeout_millis: 250
              };
              KEY_G = {
                held = "KEY_KATAKANAHIRAGANA";
                alone = "KEY_G";
                free_hold = true;
                #alone_timeout_millis: 250
              };
              KEY_V = {
                held = "KEY_FINANCE";
                alone = "KEY_V";
                free_hold = true;
                #alone_timeout_millis: 250
              };

              # CapsLock special behaviour.
              KEY_CAPSLOCK = {
                held = "KEY_LEFTCTRL";
                alone = "KEY_ESC";
                free_hold = true;
              };

              # Tab special behaviour.
              KEY_TAB = {
                held = "KEY_LEFTMETA";
                alone = "KEY_TAB";
                free_hold = true;
                #alone_timeout_millis: 50
              };

              # Right Alt special behaviour.
              KEY_APOSTROPHE = {
                held = "KEY_RIGHTALT";
                alone = "KEY_APOSTROPHE";
                free_hold = true;
              };
              KEY_RIGHTBRACE = {
                held = "KEY_RIGHTALT";
                alone = "KEY_RIGHTBRACE";
                free_hold = true;
              };
            };
          }
        ];

        keymap = [
          {
            remap = {
              "KEY_UNKNOWN-KEY_H" = "Left";
              "KEY_UNKNOWN-KEY_J" = "Down";
              "KEY_UNKNOWN-KEY_K" = "Up";
              "KEY_UNKNOWN-KEY_L" = "Right";

              "KEY_UNKNOWN-KEY_Y" = "KEY_INSERT";
              "KEY_UNKNOWN-KEY_X" = "KEY_DELETE";
              "KEY_UNKNOWN-KEY_P" = "KEY_DELETE";
              "KEY_UNKNOWN-KEY_M" = "KEY_HOME";
              # "KEY_UNKNOWN-KEY_SEMICOLON" = "KEY_ENTER";
              "KEY_UNKNOWN-KEY_SEMICOLON" = "KEY_SEMICOLON";
              "KEY_UNKNOWN-KEY_COMMA" = "KEY_END";
              "KEY_UNKNOWN-KEY_U" = "KEY_PAGEDOWN";
              "KEY_UNKNOWN-KEY_I" = "KEY_PAGEUP";

              # "KEY_UNKNOWN-KEY_S" = "ALT_L";
              "KEY_UNKNOWN-KEY_E" = "KEY_CAPSLOCK";
              "KEY_UNKNOWN-KEY_O" = "KEY_BACKSPACE";
              "KEY_UNKNOWN-KEY_F" = "KEY_ENTER";
              "KEY_UNKNOWN-KEY_N" = "KEY_ENTER";

              # "KEY_UNKNOWN-KEY_D" = "CTRL_L";
              "KEY_UNKNOWN-KEY_G" = "KEY_COMPOSE";

              "KEY_UNKNOWN-KEY_1" = "KEY_F1";
              "KEY_UNKNOWN-KEY_2" = "KEY_F2";
              "KEY_UNKNOWN-KEY_3" = "KEY_F3";
              "KEY_UNKNOWN-KEY_4" = "KEY_F4";
              "KEY_UNKNOWN-KEY_5" = "KEY_F5";
              "KEY_UNKNOWN-KEY_6" = "KEY_F6";
              "KEY_UNKNOWN-KEY_7" = "KEY_F7";
              "KEY_UNKNOWN-KEY_8" = "KEY_F8";
              "KEY_UNKNOWN-KEY_9" = "KEY_F9";
              "KEY_UNKNOWN-KEY_0" = "KEY_F10";
              "KEY_UNKNOWN-KEY_MINUS" = "KEY_F11";
              "KEY_UNKNOWN-KEY_EQUAL" = "KEY_F12";

              # "KEY_R" = "KEY_VOLUMEUP";
              # "KEY_F" = "KEY_VOLUMEDOWN";

              # Default bindings from SpaceFN: https://geekhack.org/index.php?topic: 51069

              # "KEY_RIGHTBRACE" = "KEY_PAUSE";
              # "KEY_BACKSLASH" = "KEY_INSERT";
              # "KEY_BACKSPACE" = "KEY_DELETE";

              # Moved over one key
              # This is not currently possible
              # "KEY_DOT" = "KEY_TILDE";

              # "KEY_UNKNOWN-KEY_T" = "KEY_SCROLLUP";
              # "KEY_UNKNOWN-KEY_Y" = "KEY_SCROLLDOWN";

              # "KEY_T" = "KEY_R";
              # "KEY_M" = "KEY_W";
              # "KEY_F" = "KEY_G";
              # "KEY_F" = "KEY_H";

              "KEY_RESERVED-KEY_N" = "SHIFT-KEY_SLASH";
              "KEY_RESERVED-KEY_H" = "KEY_DOT";
              "KEY_RESERVED-KEY_J" = "SHIFT-KEY_MINUS";
              "KEY_RESERVED-KEY_K" = "KEY_EQUAL";
              "KEY_RESERVED-KEY_L" = "KEY_SLASH";
              "KEY_RESERVED-KEY_U" = "KEY_BACKSLASH";
              "KEY_RESERVED-KEY_I" = "SHIFT-KEY_BACKSLASH";
              "KEY_RESERVED-KEY_O" = "SHIFT-KEY_1";

              # "KEY_S" = "KEY_LEFTSHIFT";
              "KEY_ZENKAKUHANKAKU-KEY_H" = "ALT-Left";
              "KEY_ZENKAKUHANKAKU-KEY_J" = "CTRL-KEY_PAGEUP";
              "KEY_ZENKAKUHANKAKU-KEY_K" = "CTRL-KEY_PAGEDOWN";
              "KEY_ZENKAKUHANKAKU-KEY_L" = "ALT-Right";
              "KEY_ZENKAKUHANKAKU-KEY_SEMICOLON" = "SHIFT-KEY_SEMICOLON";

              "KEY_HIRAGANA-KEY_J" = "SHIFT-KEY_9";
              "KEY_HIRAGANA-KEY_K" = "SHIFT-KEY_0";
              "KEY_HIRAGANA-KEY_H" = "SHIFT-KEY_LEFTBRACE";
              "KEY_HIRAGANA-KEY_L" = "SHIFT-KEY_RIGHTBRACE";
              "KEY_HIRAGANA-KEY_N" = "KEY_LEFTBRACE";
              "KEY_HIRAGANA-KEY_M" = "KEY_RIGHTBRACE";
              "KEY_HIRAGANA-KEY_U" = "SHIFT-KEY_COMMA";
              "KEY_HIRAGANA-KEY_I" = "SHIFT-KEY_DOT";
              "KEY_HIRAGANA-KEY_O" = "SHIFT-KEY_1";
              "KEY_HIRAGANA-KEY_SEMICOLON" = "SHIFT-KEY_SEMICOLON";

              "KEY_KATAKANAHIRAGANA-KEY_U" = "SHIFT-KEY_COMMA";
              "KEY_KATAKANAHIRAGANA-KEY_I" = "SHIFT-KEY_DOT";
              "KEY_KATAKANAHIRAGANA-KEY_H" = "SHIFT-KEY_8";
              "KEY_KATAKANAHIRAGANA-KEY_J" = "KEY_MINUS";
              "KEY_KATAKANAHIRAGANA-KEY_K" = "SHIFT-KEY_EQUAL";
              "KEY_KATAKANAHIRAGANA-KEY_L" = "KEY_SLASH";
              "KEY_KATAKANAHIRAGANA-KEY_N" = "SHIFT-KEY_3";
              "KEY_KATAKANAHIRAGANA-KEY_M" = "SHIFT-KEY_4";

              "KEY_SEMICOLON" = "KEY_ENTER";
            };
          }
        ];

        #      # HHKB: [Alt_L] [Muhenkan] [Space] [Henkan] [KatakanaHiragana]
        #      Alt_L: Ctrl_R # for Ctrl+Click
        #      Muhenkan: Ctrl_L
        #      Henkan: Shift_L
        #
        #  - name: Kana -> Windows
        #    application:
        #      not: jetbrains-idea
        #    remap:
        #      # Use Windows since Alt is annoying in Electron apps (Slack, Nocturn)
        #      KatakanaHiragana: Win_R
        #
        #  - name: Kana -> Alt
        #    application:
        #      only: jetbrains-idea
        #    remap:
        #      # Use Alt since Windows is annoying in IDEA
        #      KatakanaHiragana: Alt_L
        #
        #keymap:
        #  - name: IDEA (modified from Default)
        #    application:
        #      only: jetbrains-idea
        #    remap:
        #      # Emacs basic
        #      # C-b: left  # for Vim
        #      # C-f: right # for Vim
        #      C-p: up
        #      C-n: down
        #
        #      # Emacs word
        #      Super-b: C-left
        #      Super-f: C-right
        #
        #      # Emacs lines
        #      C-a: home # TODO: Alt-C-a
        #      C-e: end # TODO: Alt-C-e
        #      C-k: [Shift-end, backspace] # TODO: Alt-C-k
        #
        #      # Alt -> Ctrl
        #      M-a: C-a
        #      M-z: C-z
        #      M-x: C-x
        #      #M-c: C-c # use C-c for Esc, M-c for copy
        #      #M-v: C-v # use C-v for Vim, M-v for paste
        #      #M-w: C-w # avoid conflict with prefix
        #      M-t: C-t
        #      M-l: C-l
        #
        #      # actually these are vim insert mode bindings, but compatible with shell
        #      # C-w: [C-Shift-left, delete]
        #
        #      C-d: delete
        #      Super-d: C-delete
        #
        #      # workaround prefix key bug
        #      M-r:
        #        remap:
        #          '3': C-M-3
        #          '0': C-M-0
        #
        #      # workaround
        #      C-c: Esc
        #
        #  - name: Google Search
        #    application:
        #      only: Google-chrome
        #    remap:
        #      Super-o: C-Shift-tab
        #      Super-p: C-tab
        #      Super-s: C-f
        #
        #  - name: Terminal
        #    application:
        #      only: Gnome-terminal
        #    remap:
        #      Super-o: M-o
        #      Super-p: M-p
        #      Super-j: M-j
        #      Super-k: M-k
        #      Super-r: M-r
        #      Super-b: M-b
        #      Super-f: M-f
        #      Super-d: M-d
        #      Super-i: M-i
        #      Super-w: M-w
        #      Super-w: M-w
        #      Super-t: M-t
        #      Super-c: M-c
        #      Super-v: M-v
        #
        #  - name: Nocturn
        #    application:
        #      only: Nocturn
        #    remap:
        #      Super-j: M-j
        #      Super-k: M-k
        #      Super-o: M-o
        #      Super-p: M-p
        #      Super-Enter: Shift-Enter
        #
        #  - name: Slack
        #    application:
        #      only: Slack
        #    remap:
        #      Super-o: C-Shift-tab
        #      Super-p: C-tab
        #      Super-n: C-k
        #      Super-k: M-up
        #      Super-j: M-down
        #      C-M-k: Shift-Alt-up
        #      C-M-j: Shift-Alt-down
        #
        #      Super-1: C-1
        #      Super-2: C-2
        #      Super-3: C-3
        #      Super-4: C-4
        #      Super-5: C-5
        #      Super-6: C-6
        #      Super-7: C-7
        #      Super-8: C-8
        #      Super-9: C-9
        #
        #  - name: Default -- some of these are overridden by the above definitions
        #    application:
        #      not: [Google-chrome, Slack, Gnome-terminal, jetbrains-idea]
        #    remap:
        #      # Emacs basic
        #      C-b: left
        #      C-f: right
        #      C-p: up
        #      C-n: down
        #
        #      # Emacs word
        #      Super-b: C-left
        #      Super-f: C-right
        #
        #      # Emacs lines
        #      C-a: home # TODO: Alt-C-a
        #      C-e: end # TODO: Alt-C-e
        #      C-k: [Shift-end, backspace] # TODO: Alt-C-k
        #
        #      # Alt -> Ctrl
        #      Super-a: C-a
        #      Super-z: C-z
        #      Super-x: C-x
        #      Super-c: C-c
        #      Super-v: C-v
        #      Super-w: C-w
        #      Super-t: C-t
        #      Super-l: C-l
        #
        #      # Tab changes + Alt-Enter simulation
        #      Super-o: C-Shift-tab
        #      Super-p: C-tab
        #      Super-Enter: M-Enter
        #
        #      # actually these are vim insert mode bindings, but compatible with shell
        #      C-w: [C-Shift-left, delete]
        #
        #      C-d: delete
        #      Super-d: C-delete
        #
        #      # Underscore without Shift
        #      RO: Shift-RO
        #
        #      # SKK hack for Chrome
        #      C-j: C-m

        #   # Modmap for single key rebinds
        #   modmap = [
        #     {
        #       name = "Global";
        #       remap = { "CapsLock" = "Esc"; }; # globally remap CapsLock to Esc
        #     }
        #   ];

        #   # Keymap for key combo rebinds
        #   services.xremap.config.keymap = [
        #     {
        #       name = "Example ctrl-u > pageup rebind";
        #       remap = { "C-u" = "PAGEUP"; };
        #     }
        #   ];
      };
    };
  };
}
