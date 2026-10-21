# OpenSpec (github:Fission-AI/OpenSpec): Spec-Driven Development CLI, UI, and 12 workflow skills
# built statically via sandboxed CLI execution.
{ inputs, ... }:
{
  ren.aspects.dev-ai-tools-openspec = {
    agent-extensions =
      { pkgs, lib, ... }:
      let
        openspecPkg = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.openspec;
        openspecBundle =
          pkgs.runCommand "openspec-bundle"
            {
              nativeBuildInputs = [
                openspecPkg
                pkgs.nodejs
                pkgs.coreutils
              ];
            }
            ''
              work=$(mktemp -d)
              proj="$work/proj"
              home="$work/home"
              xdg="$work/xdg"
              mkdir -p "$proj" "$home" "$xdg/openspec" "$out"

              cat > "$xdg/openspec/config.json" << 'JSON'
              {
                "featureFlags": {},
                "profile": "custom",
                "delivery": "skills",
                "workflows": ["propose","explore","new","continue","apply","update","ff","sync","archive","bulk-archive","verify","onboard"]
              }
              JSON

              (
                cd "$proj"
                HOME="$home" XDG_CONFIG_HOME="$xdg" CI=true OPENSPEC_TELEMETRY=0 \
                OPENSPEC_NO_COMPLETIONS=1 DO_NOT_TRACK=1 \
                openspec init --tools claude --force --profile custom </dev/null
              )

              cp -r "$proj/.claude/skills"/* "$out/"
            '';
      in
      {
        type = "skill";
        skills = lib.mapAttrs' (name: _: lib.nameValuePair name "${openspecBundle}/${name}") (
          lib.filterAttrs (
            name: type: type == "directory" && builtins.pathExists "${openspecBundle}/${name}/SKILL.md"
          ) (builtins.readDir openspecBundle)
        );
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.openspec
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.openspecui
        ];

        programs.claude-code.settings.permissions.allow = [
          "Bash(openspec *)"
          "Bash(openspecui *)"
        ];
      };
  };
}
