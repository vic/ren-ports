# SketchyBar: bar config text (palette and scripts in _sketchybar-*.nix).
{ lib, ... }:
{
  ren.aspects.macos-wm-sketchybar-homeDarwin.homeDarwin =
    { config, pkgs, ... }:
    let
      c = import ./_sketchybar-theme.nix { inherit config; };
      s = import ./_sketchybar-scripts.nix { inherit lib pkgs c; };
      st = import ./_sketchybar-status.nix { inherit pkgs c; inherit (s) mkScript; };

      # Fixed workspace set, matching the aerospace bindings (alt-1..9). Static,
      # not queried from `aerospace list-workspaces`: the launch agent can start
      # before AeroSpace is ready, so a load-time query races and drops items.
      workspaces = map toString (lib.range 1 9);

      workspaceItems = lib.concatMapStringsSep "\n" (sid: ''
        sketchybar \
          --add item space.${sid} left \
          --subscribe space.${sid} aerospace_workspace_changed \
          --set space.${sid} icon=${sid} label.drawing=off background.drawing=on icon.padding_left=12 icon.padding_right=12 click_script="${pkgs.aerospace}/bin/aerospace workspace ${sid}" script="${s.workspaceScript}"
      '') workspaces;
    in
    {
      programs.sketchybar.config.text = ''
          # Transparent floating bar — items carry their own pills, so there's no
          # oversized blurred strip behind them.
          sketchybar --bar \
            height=32 \
            position=top \
            y_offset=8 \
            margin=12 \
            color=0x00000000 \
            blur_radius=0 \
            shadow=off \
            sticky=on \
            padding_left=0 \
            padding_right=0

          sketchybar --default \
            background.corner_radius=9 \
            background.height=26 \
            background.color=${c.surface} \
            background.drawing=off \
            icon.font="${c.font}:Bold:14.0" \
            icon.color=${c.fg} \
            label.font="${c.font}:Semibold:13.0" \
            label.color=${c.fg} \
            padding_left=3 \
            padding_right=3 \
            icon.padding_left=8 \
            icon.padding_right=6 \
            label.padding_left=2 \
            label.padding_right=8

          # --- left: workspaces + focused app ---
          sketchybar --add event aerospace_workspace_changed
          ${workspaceItems}

          sketchybar \
            --add item front_app left \
            --subscribe front_app front_app_switched \
            --set front_app icon.drawing=off background.drawing=on label.color=${c.accent} script="${s.frontAppScript}"

          # --- right: status cluster (one pill) ---
          sketchybar \
            --add item volume right \
            --subscribe volume volume_change \
            --set volume script="${st.volumeScript}"

          sketchybar \
            --add item battery right \
            --set battery update_freq=30 icon=󰁹 script="${st.batteryScript}"

          sketchybar \
            --add item clock right \
            --set clock update_freq=10 icon=󰅐 icon.color=${c.accent} script="${s.clockScript}" \
            --subscribe clock system_woke

          sketchybar \
            --add item tailscale right \
            --set tailscale update_freq=10 icon=󰖂 script="${st.tailscaleScript}"

          sketchybar \
            --add bracket status volume battery clock tailscale \
            --set status background.drawing=on background.color=${c.surface}

          # Paint dynamic items now that everything exists.
          sketchybar --update
          sketchybar --trigger aerospace_workspace_changed
          sketchybar --trigger front_app_switched
          sketchybar --trigger volume_change INFO=50
      '';
    };
}
