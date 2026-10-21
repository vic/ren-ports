# calldiff: Static & dynamic call-graph diffing tool and reachability analyzer.
{ ... }:
{
  ren.aspects.dev-ai-tools-calldiff = {
    agent-extensions = {
      type = "skill";
      skills.calldiff = ./_assets/calldiff;
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          (pkgs.writeShellApplication {
            name = "calldiff";
            runtimeInputs = [ pkgs.nodejs ];
            text = ''
              exec npx --yes calldiff "$@"
            '';
          })
        ];
      };
  };
}
