# users: the logins of the fleet (old `swarselsystems.mainUser` values and `globals.user.work`).
{ ren, ... }:
{
  ren.user.swarsel = { }; # the main user on every machine
  # the work login is PII: it lives in the repository globals
  ren.user.work.login =
    (ren.helpers.globalsOf [
      {
        __module = ren.helpers.importEncrypted ren.fleet.swarsel.globalsFile;
        __demo = true; # the static file alone
      }
    ]).user.work;
}
