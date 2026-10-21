# time: timezone from environment entity (environment.timezone defaults to "UTC").
{ ... }:
{
  ren.aspects.localization-time.os =
    { environment, ... }:
    {
      time.timeZone = environment.timezone;
    };
}
