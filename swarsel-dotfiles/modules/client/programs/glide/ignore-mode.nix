{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.glide.homeManager.programs.glide-browser.config = ''
    glide.keymaps.set("normal", "<C-Esc>", () => glide.excmds.execute("mode_change ignore"), {
      description: "Enter ignore mode",
    });
    glide.keymaps.set("ignore", "<C-Esc>", () => glide.excmds.execute("mode_change normal"), {
      description: "Leave ignore mode",
    });

    const ignore_mode_sites = [
      /https?:\/\/pokerogue\.net/,
      /https?:\/\/typelit\.io/,
      /https?:\/\/vc-impimba-1\.m\.imp\.ac\.at\/ui\/webconsole/,
    ];

    for (const pattern of ignore_mode_sites) {
      glide.autocmds.create("UrlEnter", pattern, () => {
        glide.excmds.execute("mode_change ignore");
      });
    }
  '';
}
