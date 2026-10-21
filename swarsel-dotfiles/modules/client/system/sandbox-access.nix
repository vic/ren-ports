{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.sandbox-access.nixos =
    {
      ...
    }:
    {
      networking.hosts."127.0.0.1" =
        builtins.attrValues (import "${inputs.self}/hosts/utility/vacanthouse/secrets/pii.nix").services.domains;

      security.pki.certificateFiles = [
        (sw.root "files/public/certs/ca.crt")
      ];
    };
}
