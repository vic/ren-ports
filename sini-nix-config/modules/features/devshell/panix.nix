# devshell: panix CLI (wrapper package from the panix fleet builder).
{ inputs, ... }:
{
  ren.aspects.devshell-panix.devshell =
    { system, ... }:
    {
      commands = [
        {
          package = inputs.self.packages.${system.name}.panix;
          help = "Deploy this nix config to nodes (panix, config rendered from hosts)";
        }
      ];
    };
}
