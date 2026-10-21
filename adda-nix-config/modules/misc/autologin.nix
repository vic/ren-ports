# autologin: display-manager autologin of the user, when a display manager is enabled
{ ren, ... }:
{
  # autologin is context-aware, parametric aspect.
  # it applies only if the context has at least { user }
  # meaning that has access to user data
  ren.aspects.autologin.os =
    {
      user,
      config,
      lib,
      ...
    }:
    lib.mkIf config.services.displayManager.enable {
      services.displayManager.autoLogin.enable = true;
      services.displayManager.autoLogin.user = user.name;
    };
}
