# devshell: colmena CLI.
{ inputs, ... }:
{
  ren.aspects.devshell-colmena.devshell =
    { system, ... }:
    { pkgs, ... }:
    let
      colmena = inputs.colmena.packages.${system.name}.colmena.override { nix-eval-jobs = pkgs.nix-eval-jobs; };
    in
    {
      packages = [ colmena ];
      commands = [
        {
          package = colmena;
          help = "Build and deploy this nix config to nodes";
        }
      ];
    };
}
