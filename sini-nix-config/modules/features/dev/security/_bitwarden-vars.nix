# Shared by the bitwarden linux files. A headless host has no login keyring and no display to
# prompt on, so the master password file (agenix) is the unattended source; self-gated on existence.
# Create it with: agenix edit .secrets/users/<user>/bitwarden-master-password.age
{
  config,
  lib,
  user,
  isGraphical,
}:
{
  masterPasswordFile = user.secretPath + "/bitwarden-master-password.age";
  hasMasterPassword = builtins.pathExists (user.secretPath + "/bitwarden-master-password.age");
  masterPasswordPath = config.age.secrets.bitwarden-master-password.path or "";
  # graphical: unlock waits for the display; headless: unattended on default.target
  unlockTarget = if isGraphical then "graphical-session.target" else "default.target";
}
