{
  alsa-lib,
  fetchFromGitHub,
  lib,
  openssl,
  pkg-config,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "pinepods-firewood";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "madeofpendletonwool";
    repo = "pinepods-firewood";
    tag = finalAttrs.version;
    hash = "sha256-JpjYuBLJEtsUwjzFxatx4GuuKStEEOHJaSrhzmpjrN8=";
  };

  cargoHash = "sha256-85rtFRWy9e9iJAn5Z4sV+A9wx1eqAjJhpVrOHa6gAcw=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    openssl
    alsa-lib
  ];

  meta = {
    description = "Terminal client for PinePods, a self-hosted podcast sync server";
    homepage = "https://github.com/madeofpendletonwool/pinepods-firewood";
    license = lib.licenses.gpl3Only;
    mainProgram = "pinepods_firewood";
    platforms = lib.platforms.linux;
  };
})
