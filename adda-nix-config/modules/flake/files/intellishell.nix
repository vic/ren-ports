# intellishell: the generated .intellishell command file (intelli-shell's per-project recipes).
{ ren, ... }:
{
  ren.aspects.files-intellishell = {
    at = ren.system.x86_64-linux;
    files =
      { config, ... }:
      {
        files.file.".intellishell" = {
          format = config.files.warning.formatAs "sh";
          text = /* sh */ ''
            # Switch to a NixOS configuration.
            just switch

            # Switch #host to a NixOS configuration.
            just host::switch {{host}}

            # Build a NixOS configuration for a #host.
            just host::build {{host}}

            # Run the OS repl.
            just repl

            $ host: nu --commands ' nix eval --impure --expr "(builtins.attrNames (builtins.getFlake (toString ~/.nixos-config)).nixosConfigurations)" --json | from json | to text '
          '';
        };
      };
  };
}
