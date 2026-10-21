# security: gpg and its agent, for signed commits
{ ren, ... }:
{
  # `vcs` signs Git and Jujutsu commits with `opt.vcs.signingKey`, and that needs gpg plus an agent that can ask for the
  # passphrase.
  ren.aspects.security-gpg.homeManager =
    {
      host,
      pkgs,
      ...
    }:
    {
      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;

        # A headless host has no X/Wayland display for pinentry-qt to open on, and a prompt that cannot be drawn is
        # a signing operation that hangs over SSH instead of failing. The curses pinentry draws in the terminal that
        # triggered the signature.
        pinentry.package = if host.workstation then pkgs.pinentry-qt else pkgs.pinentry-curses;
      };
    };
}
