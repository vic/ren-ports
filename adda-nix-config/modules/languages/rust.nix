# rust: editor wiring and cargo abbreviations for Rust.
{ ren, ... }:
let
  addax = ren.helpers;
  inherit (addax) getExeName getExeName';
in
{
  ren.aspects.languages-rust.zed-extensions = { ... }: [ "rust-snippets" ];

  ren.aspects.languages-rust.helixLanguages =
    { pkgs, ... }:
    {
      language = [
        {
          name = "rust";
          language-servers = [
            (getExeName pkgs.rust-analyzer)
          ];
        }
      ];
      language-server = {
        rust-analyzer = {
          config = {
            cargo.features = "all";
            check.command = getExeName pkgs.clippy;
          };
        };
      };
    };

  ren.aspects.languages-rust.abbreviations = { pkgs, ... }: with pkgs;
    {
      cr = "${getExeName cargo}";
      cra = "${getExeName cargo} add"; # Add dependencies to Cargo.toml
      crb = "${getExeName cargo} build";
      crbr = "${getExeName cargo} build --release";
      crc = "${getExeName cargo} check";
      crcl = "${getExeName cargo} clean";
      crd = "${getExeName cargo} doc";
      crdo = "${getExeName cargo} doc --open";
      crdnd = "${getExeName cargo} doc --no-deps";
      crdndo = "${getExeName cargo} doc --no-deps --open";
      crni = "${getExeName cargo} init";
      crnil = "${getExeName cargo} init --lib";
      cri = "${getExeName cargo} install";
      crl = "${getExeName cargo} --list"; # List all subcommands of Cargo including the custom ones.
      crn = "${getExeName cargo} new";
      crnl = "${getExeName cargo} new --lib";
      crr = "${getExeName cargo} run --";
      crrb = "${getExeName cargo} run --bin";
      crrq = "${getExeName cargo} run --quiet --";
      crrp = "${getExeName cargo} run -p --";
      crrr = "${getExeName cargo} run --release --";
      crrrb = "${getExeName cargo} run --release --bin";
      crrrq = "${getExeName cargo} run --release --quiet --";
      crt = "${getExeName cargo} test";
      crti = "${getExeName cargo} test -- --ignored";
      crtp = "${getExeName cargo} test -p";
      crtt = "${getExeName cargo} test --test";
      crp = "${getExeName cargo} publish";
      cru = "${getExeName cargo} update";
      cruf = "${getExeName cargo} upgrade";
      cry = "${getExeName cargo} yank";
      cryv = "${getExeName cargo} yank --vers";
      crw = "${getExeName cargo} watch";
      # 'cargo watch -- cargo <cargo_command_to_run> [<parameters>]', such as 'cargo watch -- cargo run --release'
      crwc = "${getExeName cargo} watch -- ${getExeName cargo}";
      crwa = "${getExeName cargo} watch -x check -x test -x run";

      doc_crates_list = "${getExeName cargo} doc && tree -d -L 1 target/doc";
      rust_doc = "${getExeName' rustup "rustup"} doc";
    };
}
