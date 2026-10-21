{ ren, ... }:
{
  ren.aspects.gaming = {
    includes = with ren.aspects; [
      hardware-gamepad
      app-gaming-nix-ld
      app-gaming-steam
      app-gaming-sunshine
      app-gaming-mangohud
      app-gaming-emulation
      app-gaming-umu-launcher
    ];
  };
}
