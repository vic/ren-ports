{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.time.nixos.config = {
    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "de_AT.UTF-8";
        LC_IDENTIFICATION = "de_AT.UTF-8";
        LC_MEASUREMENT = "de_AT.UTF-8";
        LC_MONETARY = "de_AT.UTF-8";
        LC_NAME = "de_AT.UTF-8";
        LC_NUMERIC = "de_AT.UTF-8";
        LC_PAPER = "de_AT.UTF-8";
        LC_TELEPHONE = "de_AT.UTF-8";
        LC_TIME = "de_AT.UTF-8";
      };
    };
    time = {
      timeZone = "Europe/Vienna";
      # hardwareClockInLocalTime = true;
    };
  };
}
