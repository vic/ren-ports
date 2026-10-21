{
  git,
  lib,
  qt6,
  rustPlatform,
  src,
  symlinkJoin,
  writeShellScript,
  writeText,
}:
let
  # cxx-qt-build reads every module's .prl from the single QT_INSTALL_LIBS qmake reports, but nixpkgs splits Qt into one
  # prefix per module; hand it a qmake that reports a merged prefix.
  qtPrefix = symlinkJoin {
    name = "rimstack-qt-prefix";
    paths = [
      qt6.qtbase
      qt6.qtdeclarative
    ];
  };
  qtConf = writeText "qt.conf" ''
    [Paths]
    Prefix=${qtPrefix}
  '';
  qmake = writeShellScript "qmake" ''exec ${lib.getExe' qt6.qtbase "qmake"} -qtconf ${qtConf} "$@"'';
in
rustPlatform.buildRustPackage {
  pname = "rimstack";
  version = "${(lib.importTOML "${src}/Cargo.toml").workspace.package.version}-unstable-${
    lib.substring 0 8 src.lastModifiedDate
  }";

  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = [ qt6.wrapQtAppsHook ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
  ];

  # After the qtbase setup hook, which exports its own QMAKE.
  preBuild = ''
    export QMAKE=${qmake}
  '';

  # Upstream's default branch declares a rust-version newer than nixpkgs' rustc.
  cargoBuildFlags = [
    "--ignore-rust-version"
    "--package"
    "rimstack-app"
  ];
  # The tests of the app crate need a display; core has the logic.
  cargoTestFlags = [
    "--ignore-rust-version"
    "--package"
    "rimstack-core"
  ];

  nativeCheckInputs = [ git ];
  checkFlags = [
    # Copies /bin/sleep, absent in the sandbox.
    "--skip=sources::maintenance::tests::a_game_started_now_is_seen_running_and_not_once_it_ended"
  ];

  qtWrapperArgs = [
    # Git-sourced mods need Git for cloning and updating.
    "--prefix PATH : ${lib.makeBinPath [ git ]}"
  ];

  postInstall = ''
    install -Dm644 crates/app/assets/rimstack.desktop -t $out/share/applications
    install -Dm644 crates/app/assets/rimstack.svg -t $out/share/icons/hicolor/scalable/apps
  '';

  meta = {
    description = "Fast RimWorld mod manager";
    homepage = "https://github.com/TheForgotten69/RimStack";
    license = lib.licenses.gpl3Plus;
    mainProgram = "rimstack";
  };
}
