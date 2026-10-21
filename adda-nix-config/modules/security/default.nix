# security: tirith/andcli on the user, firejail+bubblewrap on the OS, clamav/gpg/sops as children
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.security.includes = with ren.aspects; [
    security-clamav
    security-gpg
    security-sops
  ];

  ren.aspects.security.homeManager =
    {
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        pwgen

        veracrypt
      ];

      programs.tirith = {
        enable = true;
        enableBashIntegration = false;
        enableFishIntegration = false;
        allowlist = [
          "localhost"
        ];
        policy = {
          fail_mode = "open";
          allow_bypass = true;
          # version = 1;
          # severity_overrides = {
          #   docker_untrusted_registry = "CRITICAL";
          #   curl_pipe_shell = "LOW";
          #   wget_pipe_shell = "LOW";
          #   pipe_to_interpreter = "LOW";
          #   punycode_domain = "LOW";
          #   confusable_domain = "LOW";
          #   shortened_url = "LOW";
          # confusable_domain, punycode_domain, mixed_script_in_label
          # curl_pipe_shell, wget_pipe_shell, pipe_to_interpreter
          # ansi_escapes, control_chars
          # bidi_controls, zero_width_chars
          # hidden_multiline
          # raw_ip_url
          # plain_http_to_sink
          # git_typosquat
          # double_encoding
          # };
        };
      };

      programs.andcli = {
        enable = true;
        settings = {
          type = "aegis";
          # options = {
          #   show_usernames = true;
          # };
          # file = "${config.home.homeDirectory}/synchronized/Sync/backup/Aegis Vault/"
        };
      };

      # Create .desktop file integration for andcli
      xdg.desktopEntries.andcli = {
        name = "Andcli";
        genericName = "Andcli Vault Manager";
        comment = "Manage TOTP encrypted vaults";
        exec = lib.getExe (addax.selfPackages pkgs).andcliWrapper;
        terminal = true;
        categories = [ "Utility" ];
        mimeType = [ "application/x-andcli-vault" ];
      };
    };

  ren.aspects.security.os =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        bubblewrap
      ];

      programs.firejail = {
        enable = true;
        wrappedBinaries =
          # let
          #   profile = name: "${pkgs.firejail}/etc/firejail/${name}.profile";
          # in
          {
            #   firefox = {
            #     executable = "${lib.getBin pkgs.firefox}/bin/firefox";
            #     profile = profile "firefox";
            #   };
            #   mpv = {
            #     executable = "${lib.getBin pkgs.mpv}/bin/mpv";
            #     profile = profile "mpv";
            #   };
            # };
          };
      };
    };

  ren.aspects.pkg-andcliWrapper.at = ren.system.x86_64-linux;
  ren.aspects.pkg-andcliWrapper.packages =
    { system, ... }:
    let
      pkgs = system.legacyPackages;
    in
    {
      andcliWrapper = pkgs.writeShellApplication {
        name = "andcliWrapper";
        meta.description = "Wrapper around andcli to open the latest synchronized backup of Aegis TOTP vault.";
        text = /* nu */ ''
          ${addax.getExeName pkgs.andcli} "$(
            ${addax.getExeName pkgs.eza} --absolute --sort modified ~/synchronized/Sync/backup/Aegis \
            | tail -1 \
            | cut --delimiter ' ' --fields 12 \
          )"
        '';
      };
    };
  ren.aspects.security.aliases =
    { lib, pkgs, ... }:
    {
      andcli = lib.getExe (addax.selfPackages pkgs).andcliWrapper;
    };
}
