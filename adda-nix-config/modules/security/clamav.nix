# security: ClamAV scanner
{ ren, ... }:
{
  ren.aspects.security-clamav.os =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        clamav
      ];
      # services.clamav = {
      #   updater.enable = true;
      #   daemon.enable = true;
      #   fangfrisch.enable = true;
      #   scanner.enable = true;
      #   clamonacc.enable = true;
      #   daemon.settings = {
      #     OnAccessPrevention = true;
      #     OnAccessIncludePath = [ "~/downloads" ];
      #   };
      # };
    };
}
