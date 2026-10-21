{ ren, ... }:
{
  ren.aspects.vault = {
    includes = with ren.aspects; [
      svc-security-vault
    ];
  };
}
