# Loki datasource ref + template-variable builders for the log dashboards.
# Stable uids give stable URLs; the loki datasource uid is pinned in grafana-datasources.nix.
rec {
  lokiDs = {
    type = "loki";
    uid = "loki";
  };

  mkLabelVar = name: query: {
    inherit name;
    type = "query";
    datasource = lokiDs;
    inherit query;
    refresh = 2;
    includeAll = true;
    multi = true;
    allValue = ".+";
    current = {
      selected = true;
      text = [ "All" ];
      value = [ "$__all" ];
    };
  };

  searchVar = {
    name = "search";
    type = "textbox";
    label = "search";
    current = {
      text = "";
      value = "";
    };
  };
}
