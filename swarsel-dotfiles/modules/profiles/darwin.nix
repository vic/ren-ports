# profile-darwin: the mac base (old generic globals is a helper now)
{ ren, ... }:
{
  ren.aspects.profile-darwin.includes = [
    ren.aspects.settings
    ren.aspects.home-manager
    ren.aspects.meta
    ren.aspects.pii
  ];
}
