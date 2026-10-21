# readme fragment: logo (order 5, before header). logo.png sits next to this file.
{ ren, ... }:
{
  ren.aspects.docs-logo = {
    at = ren.fleet.sini;
    readme = {
      order = 5;
      text = ''
        <div align="center">
          <img src="https://raw.githubusercontent.com/sini/nix-config/main/modules/docs/logo/logo.png" width="120px" />
        </div>

        <br />
      '';
    };
  };
}
