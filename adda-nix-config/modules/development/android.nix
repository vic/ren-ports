# android: adb tooling and the adbusers/kvm groups for the user.
{ ren, ... }:
{
  ren.aspects.development-android = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          android-tools
        ];
      };
    account = {
      extraGroups = [
        "adbusers"
        "kvm"
      ];
    };
  };
}
