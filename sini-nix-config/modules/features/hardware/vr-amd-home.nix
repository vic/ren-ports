{ inputs, ... }:
{
  # Third file of hardware-vr-amd: home-manager side (OpenXR/OpenVR paths, flatpak WiVRn).
  ren.aspects.hardware-vr-amd.homeManagerModules = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  ren.aspects.hardware-vr-amd.homeManager =
    { config, pkgs, ... }:
    {
      xdg.configFile = {
        "openxr/1/active_runtime.json".source = "${pkgs.monado}/share/openxr/1/openxr_monado.json";
        "openvr/openvrpaths.vrpath".text =
          let
            steam = "${config.xdg.dataHome}/Steam";
          in
          builtins.toJSON {
            version = 1;

            jsonid = "vrpathreg";

            external_drivers = [ "${pkgs.monado}/share/steamvr-monado" ];

            config = [ "${steam}/config" ];

            log = [ "${steam}/logs" ];

            runtime = [ "${pkgs.xrizer}/lib/xrizer" ];
          };

      };

      home = {
        packages = [ pkgs.flatpak ];

        sessionVariables = {
          XDG_DATA_DIRS = "$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
        };
      };

      services.flatpak = {
        enable = true;
        packages = [
          "io.github.wivrn.wivrn"
          "com.github.tchx84.Flatseal"
          "org.freedesktop.Bustle"
          "com.valvesoftware.Steam"
        ];

        update.auto = {
          enable = true;
          onCalendar = "weekly";
        };

        overrides = {
          "com.valvesoftware.Steam".Context = {
            filesystems = [
              "xdg-run/wivrn:ro"
              "xdg-data/flatpak/app/io.github.wivrn.wivrn:ro"
              "xdg-config/openxr:ro"
              "xdg-config/openvr:ro"
            ];
          };
        };
      };

      xdg.mimeApps = {
        defaultApplications = {
          "x-scheme-handler/steam" = "steam.desktop";
          "x-scheme-handler/vrmonitor" = "valve-URI-vrmonitor.desktop";
          "application/x-vrmonitor" = "valve-vrmonitor.desktop";
        };
        associations.added = {
          "x-scheme-handler/steam" = "steam.desktop";
          "x-scheme-handler/vrmonitor" = "valve-URI-vrmonitor.desktop";
          "application/x-vrmonitor" = "valve-vrmonitor.desktop";
        };
      };

      home.file.".local/share/monado/hand-tracking-models".source = pkgs.fetchgit {
        url = "https://gitlab.freedesktop.org/monado/utilities/hand-tracking-models";
        sha256 = "x/X4HyyHdQUxn3CdMbWj5cfLvV7UyQe1D01H93UCk+M=";
        fetchLFS = true;
      };
    };
}
