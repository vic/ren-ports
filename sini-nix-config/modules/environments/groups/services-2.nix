# Group instances: service access (OAuth2 grants), part 2.
{ ren, ... }:
{
  ren.group."argocd.access" = {
    labels = [ "oauth-grant" ];
    description = "ArgoCD access";
    members = [
      ren.group.users
    ];
  };
  ren.group."argocd.admins" = {
    labels = [ "oauth-grant" ];
    description = "ArgoCD admin role";
    members = [
      ren.group.admins
    ];
  };
  ren.group."forgejo.access" = {
    labels = [ "oauth-grant" ];
    description = "Forgejo access";
    members = [
      ren.group.users
    ];
  };
  ren.group."forgejo.admins" = {
    labels = [ "oauth-grant" ];
    description = "Forgejo admin role";
    members = [
      ren.group.admins
    ];
  };
  ren.group."vpn.users" = {
    labels = [ "oauth-grant" ];
    description = "Headscale VPN access";
    members = [
      ren.group.admins
      ren.group.system-access
      ren.group.server-access
      ren.group.workstation-access
    ];
  };
  ren.group."open-webui.access" = {
    labels = [ "oauth-grant" ];
    description = "Open WebUI access";
    members = [
      ren.group.admins
    ];
  };
  ren.group."open-webui.admins" = {
    labels = [ "oauth-grant" ];
    description = "Open WebUI admin role";
    members = [
      ren.group.admins
    ];
  };
  ren.group."coder.access" = {
    labels = [ "oauth-grant" ];
    description = "Coder access";
    members = [
      ren.group.users
    ];
  };
  ren.group."coder.admins" = {
    labels = [ "oauth-grant" ];
    description = "Coder admin role";
    members = [
      ren.group.admins
    ];
  };
  ren.group."opkssh.access" = {
    labels = [ "oauth-grant" ];
    description = "Members may obtain an opkssh OIDC SSH token from kanidm.";
    members = [
      ren.group.admins
      ren.group.system-access
      ren.group.server-access
      ren.group.workstation-access
    ];
  };
}
