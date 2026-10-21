# ninfer package: upstream flake build patched to accept Python literals in tool calls.
{ inputs, pkgs }:
# Qwen writes `False` for some boolean tool parameters; upstream drops the whole call
# to text on it. The patch maps Python literals and flips upstream's test to match,
# and only that test is built and run (the others need the GPU).
inputs.ninfer-3090.packages.${pkgs.stdenv.hostPlatform.system}.ninfer.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./_assets/ninfer-python-literals.patch ];
  nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.python3 ];
  cmakeFlags = map (f: if f == "-DBUILD_TESTING=OFF" then "-DBUILD_TESTING=ON" else f) old.cmakeFlags;
  ninjaFlags = [
    "ninfer"
    "ninfer-serve"
    "ninfer_tool_call_parser_test"
  ];
  doCheck = true;
  checkPhase = "tests/ninfer_tool_call_parser_test";
})
