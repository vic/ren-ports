# helpers: import sops-encrypted .nix files (repo.secrets) through the nix-plugins extra builtin.
# largely based on https://github.com/oddlama/nix-config/blob/main/modules/secrets.nix
{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  # If the given expression is a bare set, it will be wrapped in a function,
  # so that the imported file can always be applied to the inputs, similar to
  # how modules can be functions or sets.
  constSet = x: if builtins.isAttrs x then (_: x) else x;
  # Try to access the extra builtin we loaded via nix-plugins.
  # Throw an error if that doesn't exist.
  sopsImportEncrypted =
    assert lib.assertMsg (builtins ? extraBuiltins.sopsImportEncrypted)
      "The extra builtin 'sopsImportEncrypted' is not available, so repo.secrets cannot be decrypted. Did you forget to add nix-plugins and point it to `./files/nix/extra-builtins.nix` ?";
    builtins.extraBuiltins.sopsImportEncrypted;
in
{
  # This "imports" an encrypted .nix.enc file by evaluating the decrypted content.
  # Plain .nix files (e.g. the demo secrets) are imported directly.
  ren.helpers.importEncrypted =
    path:
    constSet (
      if !builtins.pathExists path then
        { }
      else if lib.hasSuffix ".enc" (toString path) then
        sopsImportEncrypted path
      else
        import path
    );
}
