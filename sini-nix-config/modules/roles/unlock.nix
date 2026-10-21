{ ren, ... }:
{
  ren.aspects.unlock = {
    includes = with ren.aspects; [
      boot-network-initrd
      svc-security-tang
    ];
  };
}
