# sudo-rs (sudo disabled).
{ ... }:
{
  ren.aspects.security-sudo.nixos.security = {
    sudo.enable = false;
    sudo-rs = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = false;
    };
  };
}
