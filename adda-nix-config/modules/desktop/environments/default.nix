# desktop-environments: session/greeter side of a graphical host, includes plasma
{ ren, ... }:
{
  # Desktop environments: the session/greeter side of a graphical host (KWin, plasma-login-manager, …), as opposed to
  # `desktop`, which is the generic graphical plumbing (X/Wayland, GPUs, portals, user dirs).
  ren.aspects.desktop-environments.includes = with ren.aspects; [
    desktop-environments-plasma
  ];

  # The display manager is `display-manager.service`, aliased to whichever greeter the DE installs (e.g., plasmalogin ).
  # A headless host boots to a text console (desktop-headlessBoot), so the session has to be started by hand.
  ren.aspects.desktop-environments.abbreviations = { ... }: {
    desktop-start = "sudo systemctl start display-manager.service";
    desktop-stop = "sudo systemctl stop display-manager.service";
  };
}
