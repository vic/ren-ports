{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.firefox.homeManager =
    {
      globals-defs,
      config,
      osConfig ? null,
      lib,
      pkgs,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { host = null; inherit globals config; inherit osConfig; };
      vars = sw.varsOf { inherit config lib pkgs globals; };
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "firefox" ];
        programs = {
          firefox = {
            enable = true;
            package = pkgs.firefox; # uses overrides
            configPath = ".mozilla/firefox";
            policies = vars.browserPolicies;
            profiles = {
              checker = lib.recursiveUpdate {
                id = 5;
                settings."browser.startup.homepage" = confLib.getConfig.repo.secrets.common.checkerURLs;
              } vars.firefox;
              default = lib.recursiveUpdate {
                id = 0;
                isDefault = true;
                settings."browser.startup.homepage" = "https://lobste.rs";
              } vars.firefox;
            };
          };
          zsh.sessionVariables.MOZ_DISABLE_RDD_SANDBOX = "1";
        };
        xdg.desktopEntries.firefox_checker = {
          categories = [ "Application" ];
          exec = "firefox -p checker";
          genericName = "Firefox checker";
          icon = "firefox";
          name = "Firefox (checker)";
          terminal = false;
        };
      };
    };
}
