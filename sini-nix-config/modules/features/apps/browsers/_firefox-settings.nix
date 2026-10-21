{
  # General
  "intl.accept_languages" = "en-US,en";
  "browser.startup.page" = 3;
  "browser.aboutConfig.showWarning" = false;
  "browser.ctrlTab.sortByRecentlyUsed" = false;
  "browser.download.useDownloadDir" = false;
  "privacy.clearOnShutdown.history" = false;

  # Dev console
  "devtools.chrome.enabled" = true;
  # Crash reporting
  "browser.tabs.crashReporting.sendReport" = false;
  "accessibility.typeaheadfind.enablesound" = false;
  "general.autoScroll" = true;

  # Hardware acceleration
  "gfx.webrender.all" = true;
  "widget.dmabuf.force-enabled" = true;
  "media.av1.enabled" = true;
  "media.ffmpeg.vaapi.enabled" = true;
  "media.ffvpx.enabled" = false;
  "media.rdd-ffmpeg.enabled" = true;
  "media.rdd-vpx.enabled" = true;
  "media.rdd-process.enabled" = true;

  "shimmer.remove-winctr-buttons" = true;
  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  "svg.context-properties.content.enabled" = true;
  "browser.search.suggest.enabled" = true;
  "captivedetect.canonicalURL" = "http://detectportal.firefox.com/canonical.html";
  "network.captive-portal-service.enabled" = true;
  "network.connectivity-service.enabled" = true;
  "extensions.autoDisableScopes" = 0;

  "app.normandy.enabled" = false;
  "app.shield.optoutstudies.enabled" = false;

  # Privacy
  "privacy.donottrackheader.enabled" = true;
  "privacy.trackingprotection.enabled" = true;
  "privacy.trackingprotection.socialtracking.enabled" = true;
  "privacy.userContext.enabled" = true;
  "privacy.userContext.ui.enabled" = true;
  "browser.send_pings" = false;

  # Telemetry
  "toolkit.telemetry.archive.enabled" = false;
  "toolkit.telemetry.enabled" = false;
  "toolkit.telemetry.server" = "";
  "toolkit.telemetry.unified" = false;
  "extensions.webcompat-reporter.enabled" = false;
  "datareporting.policy.dataSubmissionEnabled" = false;
  "datareporting.healthreport.uploadEnabled" = false;
  "browser.ping-centre.telemetry" = false;
  "browser.urlbar.eventTelemetry.enabled" = false;

  # Disable useless features
  "extensions.pocket.enabled" = false;
  "extensions.abuseReport.enabled" = false;
  "extensions.formautofill.creditCards.enabled" = false;
  "identity.fxaccounts.enabled" = false;
  "identity.fxaccounts.toolbar.enabled" = false;
  "identity.fxaccounts.pairing.enabled" = false;
  "identity.fxaccounts.commands.enabled" = false;
  "browser.contentblocking.report.lockwise.enabled" = false;
  "browser.uitour.enabled" = false;
  "browser.newtabpage.activity-stream.showSponsored" = false;
  "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

  # Disable annoying web features
  "dom.push.enabled" = false;
  "dom.push.connection.enabled" = false;
  "dom.battery.enabled" = false;
  "dom.private-attribution.submission.enabled" = false;
}
