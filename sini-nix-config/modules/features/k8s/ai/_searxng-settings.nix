# searxng engines, their egress hosts and the settings.yml they render.
# Each engine's endpoints, from its engines/*.py, are the egress allow-list
# (engineHosts), so adding an engine means adding its hosts there.
{
  engines = [
    "google"
    "bing"
    "duckduckgo"
    "mojeek"
    "startpage"
    "wikipedia"
    "github"
    "stackoverflow"
  ];

  engineHosts = [
    "duckduckgo.com"
    "html.duckduckgo.com"
    "lite.duckduckgo.com"
    "links.duckduckgo.com"
    "www.google.com"
    "www.bing.com"
    "www.mojeek.com"
    "www.startpage.com"
    "en.wikipedia.org"
    "api.github.com"
    "api.stackexchange.com"
  ];

  settingsFor = engines: baseUrl: {
    use_default_settings.engines.keep_only = engines;
    general = {
      instance_name = "search";
      enable_metrics = false;
    };
    search = {
      formats = [
        "html"
        "json"
      ];
      autocomplete = "";
    };
    server = {
      base_url = baseUrl;
      limiter = false;
      public_instance = false;
      image_proxy = false;
    };
    engines = [
      {
        name = "google";
        disabled = false;
      }
      {
        name = "bing";
        disabled = false;
      }
      {
        name = "mojeek";
        inactive = false;
        disabled = false;
      }
      {
        name = "startpage";
        inactive = false;
        disabled = false;
      }
      {
        name = "wikipedia";
        language = "en";
      }
      {
        name = "github";
        categories = [
          "general"
          "it"
        ];
      }
      {
        name = "stackoverflow";
        categories = [
          "general"
          "it"
          "q&a"
        ];
      }
    ];
  };
}
