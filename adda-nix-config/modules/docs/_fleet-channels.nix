# fleet channels: one `emitter -> receiver` per Ren channel for the README channel map; the map fails to eval on a missing or stale line.
{
  apps = "system -> flake outputs";
  devshells = "system -> flake outputs";
  formatter = "system -> flake outputs";
  packages = "system -> flake outputs";
  checks = "any scope -> flake outputs";
  templates = "fleet -> flake outputs";
  flake-inputs = "any scope -> flake-file class";
  overlays = "host and user -> host";
  service-domains = "service aspects -> caddy";
  zed-extensions = "language aspects -> zed-editor";
  vscodium-extensions = "language aspects -> vscodium";
}
