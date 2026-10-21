# ichocholaty: Adda's work identity on the headless work VMs (den kept it as users.adda with userName = "ichocholaty").
{ ren, ... }:
{
  ren.user.ichocholaty = {
    description = "David (Adda) Chocholatý";
    nick = "Adda";
    realName = "David Chocholatý";
    aiRules = import ../ai/_rules.nix;
    vcs.githubTokenSops = ren.helpers.secretsPath "gh-fabrica.yaml";
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG2LSB9oGPxpYWFwb+InQHS6KCei7iKfF1MEb+KN3NpT adda@fulgur-nixos"
    ];
  };

  ren.aspects.ichocholaty = {
    at = ren.user.ichocholaty;
    includes = [ ren.aspects.workVM-user ];
  };

  # Lean counterpart of the `adda` aspect, used only on headless work servers that Adda
  #  reaches over SSH. Same user, same keys, same basic shell setup as the full `adda`
  #  aspect, but no graphical session, no personal secrets (sops/security), no syncing
  #  (file replication is a property of the user's machines, not of work boxes shared
  #  with other admins), and no development toolkit beyond a text editor and direnv.
  ren.aspects.addaServer.includes = with ren.aspects; [
    shells
    editors-helix

    console-yazi

    # Not the maintainer toolkit `languages-nix`, only the three things this repo
    #  cannot work without: Determinate Nix, envoluntary (read by the nushell config)
    #  and direnv.
    languages-nix-core
  ];
}
