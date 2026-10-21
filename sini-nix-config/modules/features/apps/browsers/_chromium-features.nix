# Folded into a single --enable-features= switch; Chromium does not
# reliably merge multiple occurrences of the flag.
{
  enabled = [
    # Wayland
    "UseOzonePlatform"
    "WaylandWindowDecorations"

    # Hardware video acceleration (mirrors firefox media.ffmpeg.vaapi.enabled)
    "VaapiVideoDecoder"
    "VaapiVideoEncoder"

    # Network-state partitioning (privacy isolation)
    "PartitionVisitedLinkDatabase"
    "PrefetchPrivacyChanges"
    "SplitCacheByNetworkIsolationKey"
    "SplitCodeCacheByNetworkIsolationKey"
    "EnableCrossSiteFlagNetworkIsolationKey"
    "PartitionConnectionsByNetworkIsolationKey"
    "StrictOriginIsolation"
    "ReduceAcceptLanguage"
    "ContentSettingsPartitioning"
  ];

  disabled = [
    # Autofill (mirrors firefox extensions.formautofill.creditCards.enabled = false)
    "AutofillServerCommunication"
    "AutofillPaymentCardBenefits"
    "AutofillPaymentCvcStorage"

    # Third-party cookie deprecation bypasses
    "TpcdHeuristicsGrants"
    "TpcdMetadataGrants"

    # Hyperlink auditing (mirrors browser.send_pings = false)
    "EnableHyperlinkAuditing"

    # New-tab-page clutter (mirrors activity-stream.showSponsored = false)
    "NTPPopularSitesBakedInContent"
    "UsePopularSitesSuggestions"
    "EnableSnippets"
    "ArticlesListVisible"
    "InterestFeedV2"

    # Privacy Sandbox / Topics (mirrors privacy.trackingprotection + private-attribution)
    "PrivacySandboxSettings4"
    "BrowsingTopics"
    "BrowsingTopicsDocumentAPI"
    "BrowsingTopicsParameters"

    # Telemetry / background fetching (mirrors toolkit.telemetry.* = false)
    "OptimizationHintsFetching"
    "MediaDrmPreprovisioning"
    "PreloadMediaEngagementData"
    "MediaEngagementBypassAutoplayPolicies"
  ];
}
