{ ren, lib, ... }:
{
  ren.kinds.user.dev-security-bitwarden = ren.lib.opt (lib.types.submodule {
    options.email = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Override email address for Bitwarden rbw configuration";
    };
  }) { };

  ren.aspects.dev-security-bitwarden = {
    homeManager =
      { user, ... }:
      {
        programs.rbw = {
          enable = true;
          settings = {
            email =
              if user.dev-security-bitwarden.email != null then
                user.dev-security-bitwarden.email
              else
                (user.identity.email or null);
            lock_timeout = 24 * 60 * 60; # 1 day
          };
        };
      };

    # macOS launchd and ssh configuration to export SSH_AUTH_SOCK globally for the Bitwarden agent.
    homeDarwin =
      { pkgs, ... }:
      {
        programs.rbw.settings.pinentry = pkgs.pinentry_mac;
      };
  };
}
