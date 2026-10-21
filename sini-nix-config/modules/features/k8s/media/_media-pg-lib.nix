# Shared media-pg data: roles, per-app databases, password secret naming. Imported by media-pg*.nix.
lib:
let
  # *arrs split data into a main db and a logs db (Servarr PostgresMainDb / PostgresLogDb).
  arrApps = [
    "sonarr"
    "radarr"
    "lidarr"
    "whisparr"
    "prowlarr"
  ];

  # bazarr and romm use a single db each.
  singleApps = [
    "bazarr"
    "romm"
  ];
in
{
  roleApps = arrApps ++ singleApps;

  passwordSecretName = app: "media-pg-${app}-password";

  # { crName -> { db, owner } }: arrs -> <app>-main/<app>-log, single-db apps -> <app>.
  databases = lib.listToAttrs (
    lib.concatMap (app: [
      (lib.nameValuePair "${app}-main" {
        db = "${app}-main";
        owner = app;
      })
      (lib.nameValuePair "${app}-log" {
        db = "${app}-log";
        owner = app;
      })
    ]) arrApps
    ++ map (app: lib.nameValuePair app { db = app; owner = app; }) singleApps
  );
}
