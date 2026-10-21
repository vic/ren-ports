# pycharm: JetBrains PyCharm Professional (flatpak).
{ ren, ... }:
{
  ren.aspects.editors-pycharm-desktop.os = {
    services.flatpak.packages = [
      "com.jetbrains.PyCharm-Professional"
    ];
  };
}
