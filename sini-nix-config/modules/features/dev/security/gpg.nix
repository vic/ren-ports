{ ren, lib, ... }:
{
  ren.kinds.user.dev-security-gpg = ren.lib.opt (lib.types.submodule {
    options.enableSshAgent = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use gpg-agent as the SSH agent";
    };
  }) { };

  ren.aspects.dev-security-gpg = {
    nixos = {
      services.pcscd.enable = true;
      hardware.gpgSmartcards.enable = true;
    };

    homeManager =
      { user, ... }:
      let
        enableSshAgent = user.dev-security-gpg.enableSshAgent;
      in
      {
        programs.gpg = {
          enable = true;

          scdaemonSettings = {
            disable-ccid = true;
          };

          settings = {
            personal-cipher-preferences = "AES256 AES192 AES";
            personal-digest-preferences = "SHA512 SHA384 SHA256";
            personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
            default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
            cert-digest-algo = "SHA512";
            s2k-digest-algo = "SHA512";
            s2k-cipher-algo = "AES256";
            charset = "utf-8";
            fixed-list-mode = true;
            no-comments = true;
            no-emit-version = true;
            keyid-format = "0xlong";
            list-options = "show-uid-validity";
            verify-options = "show-uid-validity";
            with-fingerprint = true;
            require-cross-certification = true;
            no-symkey-cache = true;
            use-agent = true;
            throw-keyids = true;
          };
        };

        services = {
          gpg-agent = {
            enable = true;
            enableExtraSocket = true;

            # enableSshSupport is deliberately NOT set. It bundles three things:
            # the `enable-ssh-support` config line, the listening ssh socket, and
            # a claim on sshAuthSock.initialization — home-manager's single owner
            # of SSH_AUTH_SOCK. Taking that claim would export gpg-agent's own
            # socket into every shell, putting gpg-agent in FRONT of
            # ssh-agent-mux. The first two are declared directly (below, and per
            # platform), so gpg-agent serves ssh keys as one upstream behind the
            # mux and never contends for the variable.

            enableBashIntegration = true;
            enableZshIntegration = true;
            enableFishIntegration = true;
            enableNushellIntegration = true;

            defaultCacheTtl = 43200;
            defaultCacheTtlSsh = 43200;
            maxCacheTtl = 86400;
            maxCacheTtlSsh = 86400;

            extraConfig = ''
              ttyname $GPG_TTY
            ''
            + lib.optionalString enableSshAgent "enable-ssh-support\n";
          };
        };
      };
  };
}
