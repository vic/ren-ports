# Agenix aspect: opt-in marker for hosts that use agenix secrets.
# Core agenix wiring (module imports, rekey config, HM sharedModules) lives in the agenix battery (L3).
# Provides the persist key for impermanence integration.
{ ... }:
{
  ren.aspects.secrets-agenix = {
    # Agenix-rekey generators state
    persist = { };
  };
}
