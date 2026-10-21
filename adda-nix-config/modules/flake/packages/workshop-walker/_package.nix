{
  autoPatchelfHook,
  buildNpmPackage,
  coreutils,
  fetchFromGitHub,
  lib,
  makeWrapper,
  nodejs_26,
  rustPlatform,
  stdenv,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "workshop-walker";
  version = "0.8.2";

  src = fetchFromGitHub {
    owner = "disconsented";
    repo = "workshop-walker";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OOY0GGqPD8BnJ34syEVjrHBeAJazpbIAIT51skx4Rak=";
  };

  cargoHash = "sha256-/74E6l8TwgoVwSdWTsFMOjL8jX/+IZHdNfbbSdMMinA=";

  # `ml_extraction.enabled = false` still blocks startup until the llama.cpp server answers.
  patches = [ ./skip-classifier-health-check-when-disabled.patch ];

  # Upstream forces clang + /usr/bin/mold as the linker.
  postPatch = ''
    rm .cargo/config.toml
  '';

  nativeBuildInputs = [
    # librocksdb-sys builds RocksDB from source and runs bindgen.
    rustPlatform.bindgenHook
    # The binary links libstdc++ (RocksDB) without an rpath to it.
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [ stdenv.cc.cc.lib ];

  cargoBuildFlags = [
    "--bin"
    "workshop-walker"
  ];
  # Tests need fixtures and a live database.
  doCheck = false;

  # Runtime resources are resolved relative to the working directory
  # (`ui/build/`, `migrations/`, `prompts/`, `config/config.toml`, `workshopdb/`), so the wrapper runs from a
  # writable per-user directory linking the store resources and holding the config and database.
  postInstall = ''
    share=$out/share/workshop-walker
    mkdir --parents $share/ui
    cp --recursive migrations prompts config $share/
    cp --recursive ${finalAttrs.passthru.ui} $share/ui/build

    wrapProgram $out/bin/workshop-walker --run '
      state=''${XDG_DATA_HOME:-$HOME/.local/share}/workshop-walker
      ${coreutils}/bin/mkdir --parents "$state/config"
      for resource in migrations prompts ui; do
        ${coreutils}/bin/ln --symbolic --force --no-target-directory '"$share"'/$resource "$state/$resource"
      done
      if [ ! -e "$state/config/config.toml" ]; then
        ${coreutils}/bin/install --mode=600 '"$share"'/config/config.example.toml "$state/config/config.toml"
        echo "workshop-walker: fill in $state/config/config.toml (Steam API key, SteamID64, biscuit keypair), then run again" >&2
        exit 1
      fi
      cd "$state"
    '
  '';

  passthru.ui = buildNpmPackage {
    pname = "${finalAttrs.pname}-ui";
    inherit (finalAttrs) src version;
    sourceRoot = "${finalAttrs.src.name}/ui";
    nodejs = nodejs_26;
    npmDepsHash = "sha256-sGecq4FyofBIXy9YmFKB7DapSRP3j61vJH6HZmSpT68=";
    installPhase = ''
      runHook preInstall
      cp --recursive build $out
      runHook postInstall
    '';
  };

  meta = {
    description = "Alternate Steam Workshop browser with dependants, language detection and properties";
    homepage = "https://github.com/disconsented/workshop-walker";
    changelog = "https://github.com/disconsented/workshop-walker/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mpl20;
    mainProgram = "workshop-walker";
    platforms = lib.platforms.linux;
  };
})
