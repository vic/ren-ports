# mkLogsDashboard: Loki log-volume + logs panels with template variables.
{ lokiDs, searchVar }:
{
  uid,
  title,
  variables,
  selector,
  volumeBy,
}:
{
  inherit uid title;
  schemaVersion = 39;
  version = 1;
  editable = true;
  time = {
    from = "now-1h";
    to = "now";
  };
  templating.list = variables ++ [ searchVar ];
  panels = [
    {
      title = "Log volume";
      type = "timeseries";
      datasource = lokiDs;
      gridPos = {
        h = 6;
        w = 24;
        x = 0;
        y = 0;
      };
      options.legend.displayMode = "list";
      fieldConfig.defaults.custom = {
        drawStyle = "bars";
        fillOpacity = 50;
      };
      targets = [
        {
          refId = "A";
          datasource = lokiDs;
          expr = "sum by (${volumeBy}) (count_over_time(${selector} |= `$search` [$__auto]))";
          legendFormat = "{{${volumeBy}}}";
        }
      ];
    }
    {
      title = "Logs";
      type = "logs";
      datasource = lokiDs;
      gridPos = {
        h = 20;
        w = 24;
        x = 0;
        y = 6;
      };
      options = {
        showTime = true;
        wrapLogMessage = true;
        enableLogDetails = true;
        sortOrder = "Descending";
        dedupStrategy = "none";
      };
      targets = [
        {
          refId = "A";
          datasource = lokiDs;
          expr = "${selector} |= `$search`";
        }
      ];
    }
  ];
}
