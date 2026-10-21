{ ren, ... }:
{
  ren.aspects.dev-security-opkssh-client = {
    homeLinux =
      {
        pkgs,
        lib,
        environment,
        ...
      }:
      let
        idmDomain = ren.helpers.domainFor environment "kanidm";
        kanidmIssuer = "https://${idmDomain}/oauth2/openid/opkssh";
        standardSock = "\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/standard-ssh-agent.sock";
      in
      {
        home.shellAliases = {
          opkssh-login = "${import ./_opkssh-login.nix pkgs lib kanidmIssuer standardSock}";
        };
      };

    homeDarwin =
      {
        pkgs,
        lib,
        environment,
        ...
      }:
      let
        idmDomain = ren.helpers.domainFor environment "kanidm";
        kanidmIssuer = "https://${idmDomain}/oauth2/openid/opkssh";
        standardSock = "$(getconf DARWIN_USER_TEMP_DIR)/standard-ssh-agent.sock";
      in
      {
        home.shellAliases = {
          opkssh-login = "${import ./_opkssh-login.nix pkgs lib kanidmIssuer standardSock}";
        };
      };
  };
}
