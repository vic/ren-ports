# latex: TeX toolchain and editor wiring.
{ ren, ... }:
{
  ren.aspects.languages-latex = {
    helixLanguages = {
      language = [
        {
          name = "latex";
          auto-format = false;
          language-servers = [
            "texlab"
          ];
          roots = [
            "main.tex"
          ];
          # formatter = {
          #   command = getExeName pkgs.;
          # };
        }
      ];
    };

    vscodium-extensions =
      { ... }:
      [
        "james-yu.latex-workshop"
      ];
    vscodiumSettings = {
      # extensions = [
      #   "james-yu.latex-workshop"
      # ];
      # settings = {
      latex-workshop = {
        bibtex-format.trailingComma = true;
        # latex.autoBuild.run = "never";
        # };
      };
      texlab.server.autoDownload = true;
    };

    zed-extensions = { ... }: [ "latex" ];

    # The toolchain itself. `helixLanguages` above references `texlab`; the zed
    #  settings below shell out to `latexindent`. This is what puts them (and an
    #  actual TeX distribution) on PATH, on headless hosts too. `scheme-medium`
    #  covers the usual packages; `latexindent` is deliberately pulled in on top —
    #  it rides along in scheme-full but is absent from the smaller schemes.
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          (texliveSmall.withPackages (
            ps: with ps; [
              scheme-medium
              latexindent
            ]
          ))
          texlab
          tex-fmt
          tectonic # Self-contained engine; handy when the full distribution would do.
        ];
      };

    zedSettings = {
      languages.LaTeX = {
        formatter = {
          external = {
            command = "latexindent";
            arguments = [
              "--local"
              "--overwriteIfDifferent"
              "--modifylinebreaks"
              "--cruft"
              ".latexindent/"
              "--logfile"
              ".latexindent/indent.log"
              "{buffer_path}"
            ];
          };
        };
      };
    };
  };
}
