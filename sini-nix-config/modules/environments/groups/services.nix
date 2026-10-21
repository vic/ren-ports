# Group instances: service access (OAuth2 grants). Dotted names kept quoted.
{ ren, ... }:
{
  ren.group."grafana.access" = {
    labels = [ "oauth-grant" ];
    description = "Grafana login";
    members = [
      ren.group.users
    ];
  };
  ren.group."search.access" = {
    labels = [ "oauth-grant" ];
    description = "SearXNG web search UI";
    members = [
      ren.group.users
    ];
  };
  ren.group."grafana.editors" = {
    labels = [ "oauth-grant" ];
    description = "Grafana editor role";
  };
  ren.group."grafana.admins" = {
    labels = [ "oauth-grant" ];
    description = "Grafana admin role";
  };
  ren.group."grafana.server-admins" = {
    labels = [ "oauth-grant" ];
    description = "Grafana server admin role";
    members = [
      ren.group.admins
    ];
  };
  ren.group."matrix.access" = {
    labels = [ "oauth-grant" ];
    description = "Matrix (Synapse) login";
    members = [
      ren.group.users
    ];
  };
  ren.group."media.access" = {
    labels = [ "oauth-grant" ];
    description = "Jellyfin access";
    members = [
      ren.group.users
    ];
  };
  ren.group."media.admins" = {
    labels = [ "oauth-grant" ];
    description = "Jellyfin admin role";
    members = [
      ren.group.admins
    ];
  };
}
