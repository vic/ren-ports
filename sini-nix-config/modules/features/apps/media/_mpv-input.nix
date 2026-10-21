# mpv extraInput; called with the merged profile table.
profiles: ''
  ` script-binding console/enable #! Console

  g cycle interpolation #! Video > Interpolation
  d cycle deinterlace #! Video > Toggle Deinterlace
  [ add speed +0.1; script-binding uosc/flash-speed #! Video > Speed > Increase Speed
  ] add speed -0.1; script-binding uosc/flash-speed #! Video > Speed > Decrease Speed
  BS set speed 1; script-binding uosc/flash-speed #! Video > Speed > Reset Speed
  b cycle-values deband "yes" "no" #! Video > Deband > Toggle Deband

  F1 af toggle "lavfi=[loudnorm=I=-14:TP=-3:LRA=4]'"; show-text "''${af}" #! Audio > Dialogue
  a cycle audio-normalize-downmix #! Audio > Toggle Normalize
  Ctrl++ add audio-delay +0.10 #! Audio > Delay > Increase Audio Delay
  Ctrl+- add audio-delay -0.10 #! Audio > Delay > Decrease Audio Delay

  Shift+g add sub-scale +0.05 #! Subtitles > Scale > Increase Subtitle Scale
  Shift+f add sub-scale -0.05 #! Subtitles > Scale > Decrease Subtitle Scale
  : add sub-pos -1 #! Subtitles > Position > Move Subtitle Up
  " add sub-pos +1 #! Subtitles > Position > Move Subtitle Down
  z add sub-delay -0.1 #! Subtitles > Delay > Decrease Subtitles Delay
  Z add sub-delay 0.1 #! Subtitles > Delay > Increase Subtitles Delay

  CTRL+0 change-list glsl-shaders clr all; show-text "Shaders cleared" #! Profiles > Clear All Shaders
  CTRL+1 apply-profile fsr-cas; show-text "Profile: ${profiles.fsr-cas.name}" #! Profiles > ${profiles.fsr-cas.name}
  CTRL+2 apply-profile generic-high; show-text "Profile: ${profiles.generic-high.name}" #! Profiles > ${profiles.generic-high.name}
  CTRL+3 apply-profile nnedi-very-high; show-text "Profile: ${profiles.nnedi-very-high.name}" #! Profiles > ${profiles.nnedi-very-high.name}
  CTRL+4 apply-profile anime4k-high-a; show-text "Profile: ${profiles.anime4k-high-a.name}" #! Profiles > ${profiles.anime4k-high-a.name}
  CTRL+5 apply-profile anime4k-high-b; show-text "Profile: ${profiles.anime4k-high-b.name}" #! Profiles > ${profiles.anime4k-high-b.name}
  CTRL+6 apply-profile anime4k-high-c; show-text "Profile: ${profiles.anime4k-high-c.name}" #! Profiles > ${profiles.anime4k-high-c.name}
  CTRL+7 apply-profile anime4k-high-aa; show-text "Profile: ${profiles.anime4k-high-aa.name}" #! Profiles > ${profiles.anime4k-high-aa.name}
  CTRL+8 apply-profile anime4k-high-bb; show-text "Profile: ${profiles.anime4k-high-bb.name}" #! Profiles > ${profiles.anime4k-high-bb.name}
  CTRL+9 apply-profile anime4k-high-ca; show-text "Profile: ${profiles.anime4k-high-ca.name}" #! Profiles > ${profiles.anime4k-high-ca.name}
''
