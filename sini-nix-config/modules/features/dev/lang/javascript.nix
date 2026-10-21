# javascript/typescript: Node.js runtime and developer tooling.
{ ... }:
{
  ren.aspects.dev-lang-javascript.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.nodejs_22
      ];
    };
}
