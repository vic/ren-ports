# Chromium. On Linux it's the native nixpkgs build configured via
# programs.chromium (chromium-linux.nix). nixpkgs chromium doesn't build on darwin, so macOS installs
# the `chromium` cask and reapplies the portable parts of the config — the
# extension set and privacy/telemetry hardening — through Chromium's managed
# policy engine. The Wayland/ozone and VAAPI bits are Linux-only.
{ ... }:
{
  ren.aspects.app-browsers-chromium = {
    homebrew-cask = [ "chromium" ];

    # macOS: the cask installs Chromium.app unconfigured, so reapply the portable
    # config through Chromium's managed-policy engine, which reads mandatory
    # policy from /Library/Managed Preferences. The Wayland/VAAPI command-line
    # flags above have no macOS analogue and are intentionally dropped.
    darwin =
      { pkgs, lib, ... }:
      let
        policy = {
          ExtensionInstallForcelist = map (
            id: "${id};https://clients2.google.com/service/update2/crx"
          ) (import ./_chromium-extensions.nix);

          # Telemetry / data collection (mirrors the disabled telemetry features)
          MetricsReportingEnabled = false;
          UrlKeyedAnonymizedDataCollectionEnabled = false;

          # Account / sync (mirrors --disable-sync)
          SyncDisabled = true;
          BrowserSignin = 0;

          # Quality of life (mirrors --no-default-browser-check + NTP declutter)
          DefaultBrowserSettingEnabled = false;
          PromotionalTabsEnabled = false;
          BackgroundModeEnabled = false;

          # Autofill (mirrors the disabled Autofill* features)
          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;

          # Privacy Sandbox / Topics (mirrors the disabled PrivacySandbox features)
          PrivacySandboxPromptEnabled = false;
          PrivacySandboxAdMeasurementEnabled = false;
          PrivacySandboxSiteEnabledAdsEnabled = false;
          PrivacySandboxFledgeEnabled = false;
          PrivacySandboxTopicsEnabled = false;

          # GPU (mirrors --ignore-gpu-blocklist intent)
          HardwareAccelerationModeEnabled = true;
        };
        plist = pkgs.writeText "org.chromium.Chromium.plist" (lib.generators.toPlist { } policy);
      in
      {
        system.activationScripts.postActivation.text = ''
          mkdir -p "/Library/Managed Preferences"
          cp -f ${plist} "/Library/Managed Preferences/org.chromium.Chromium.plist"
        '';
      };

    cacheHome.directories = [
      ".cache/chromium"
    ];

    persistHome.directories = [
      ".config/chromium"
    ];
  };
}
