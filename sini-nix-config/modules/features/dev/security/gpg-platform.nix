{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
{
  ren.aspects.dev-security-gpg = {
    homeLinux =
      {
        config,
        host,
        is,
        pkgs,
        user,
        ...
      }:
      let
        isGraphical = is ren.aspects.workstation host;
        enableSshAgent = user.dev-security-gpg.enableSshAgent;
      in
      {
        services.gpg-agent.pinentry.package =
          if isGraphical then pkgs.pinentry-gnome3 else pkgs.pinentry-tty;

        # The socket half of what enableSshSupport would have configured.
        # ListenStream assumes the default gnupg homedir — home-manager derives
        # this path from a hash of a non-default one — so the assertion keeps a
        # later homedir change from silently leaving the mux with a dead
        # upstream and no gpg keys.
        assertions = lib.optionals enableSshAgent [
          {
            assertion = config.programs.gpg.homedir == "${config.home.homeDirectory}/.gnupg";
            message = "gpg: enableSshAgent assumes the default gnupg homedir; ListenStream in systemd.user.sockets.gpg-agent-ssh must be updated for ${config.programs.gpg.homedir}.";
          }
        ];

        systemd.user.sockets.gpg-agent-ssh = lib.mkIf enableSshAgent {
          Unit = {
            Description = "GnuPG cryptographic agent (ssh-agent emulation)";
            Documentation = "man:gpg-agent(1) man:ssh-add(1) man:ssh-agent(1) man:ssh(1)";
          };
          Socket = {
            ListenStream = "%t/gnupg/S.gpg-agent.ssh";
            FileDescriptorName = "ssh";
            Service = "gpg-agent.service";
            SocketMode = "0600";
            DirectoryMode = "0700";
          };
          Install.WantedBy = [ "sockets.target" ];
        };
      };

    homeDarwin =
      {
        config,
        host,
        is,
        pkgs,
        user,
        ...
      }:
      let
        enableSshAgent = user.dev-security-gpg.enableSshAgent;
      in
      {
        services.gpg-agent.pinentry.package = pkgs.pinentry_mac;

        # Darwin equivalent of the socket above: home-manager hangs it off the
        # launchd agent, again gated on the option we are not setting.
        launchd.agents.gpg-agent.config = lib.mkIf enableSshAgent {
          RunAtLoad = true;
          Sockets.Ssh = {
            SockType = "stream";
            SockPathName = "${config.programs.gpg.homedir}/S.gpg-agent.ssh";
            SockPathMode = 384; # 0600; plists have no octal literals.
          };
        };
      };

    persistHome = {
      directories = [
        {
          directory = ".gnupg";
          mode = "0700";
        }
      ];
    };
  };
}
