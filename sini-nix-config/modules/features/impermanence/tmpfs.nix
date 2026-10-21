{ ... }:
{
  ren.aspects.impermanence-tmpfs.nixos = {
    boot.tmp = {
      useTmpfs = true;
      cleanOnBoot = true;
    };
  };
}
