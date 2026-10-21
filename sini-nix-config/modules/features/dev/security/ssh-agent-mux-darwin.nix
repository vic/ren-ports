{ ... }:
{
  ren.aspects.dev-security-ssh-agent-mux.homeDarwin =
    { pkgs, config, ... }:
    let
      s = import ./_mux-darwin-scripts.nix { inherit pkgs config; };
      inherit (s) signingKeyLoader wrapper;
    in
    {
      home.sessionVariables = {
        SSH_AUTH_SOCK = ''$(DARWIN_TEMP=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null); echo "$DARWIN_TEMP/ssh-agent-mux.sock")'';
      };

      # Export the mux socket into the GUI login session, so it reaches apps
      # and scripts rather than only interactive shells. This lived in the gpg
      # aspect and pointed at gpg's own socket; it belongs with whichever agent
      # actually fronts ssh, which is now the mux.
      launchd.agents.ssh-auth-sock = {
        enable = true;
        config = {
          ProgramArguments = [
            "/bin/sh"
            "-c"
            ''DARWIN_TEMP=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null); /bin/launchctl setenv SSH_AUTH_SOCK "$DARWIN_TEMP/ssh-agent-mux.sock"''
          ];
          RunAtLoad = true;
        };
      };

      launchd.agents.standard-ssh-agent = {
        enable = true;
        config = {
          ProgramArguments = [
            "/bin/sh"
            "-c"
            ''DARWIN_TEMP=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null); exec ${pkgs.openssh}/bin/ssh-agent -D -a "$DARWIN_TEMP/standard-ssh-agent.sock"''
          ];
          RunAtLoad = true;
          KeepAlive = true;
        };
      };

      launchd.agents.standard-ssh-agent-load-key = {
        enable = true;
        config = {
          ProgramArguments = [ "${signingKeyLoader}" ];
          RunAtLoad = true;
        };
      };

      launchd.agents.ssh-agent-mux = {
        enable = true;
        config = {
          ProgramArguments = [ "${wrapper}" ];
          RunAtLoad = true;
          KeepAlive = true;
        };
      };

      launchd.agents.ssh-auth-sock-mux = {
        enable = true;
        config = {
          ProgramArguments = [
            "/bin/sh"
            "-c"
            ''/bin/launchctl setenv SSH_AUTH_SOCK "$(/bin/sh -c 'DARWIN_TEMP=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null); echo "$DARWIN_TEMP/ssh-agent-mux.sock"')"''
          ];
          RunAtLoad = true;
        };
      };
    };
}
