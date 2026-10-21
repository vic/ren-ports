{ ... }:
{
  ren.aspects.dev-security-ssh-agent-mux = {
    # Build ssh-agent-mux from the sini fork. It bumps ssh-agent-lib 0.5.1 ->
    # 0.6.0 for the `PublicCredential` (Key | Cert) type, so an SSH *certificate*
    # in an upstream agent — e.g. the opkssh OIDC cert loaded into the standard
    # agent — round-trips through the mux instead of decoding to a lossy opaque
    # key and re-serializing a truncated identity list, which made `ssh-add -l`
    # fail with "incomplete message" and dropped every other agent's keys
    # (overhacked/ssh-agent-mux#56). The fork is branched off upstream main, so it
    # also carries the merged list-errors tolerance (#94): a misbehaving upstream
    # (rbw mid-unlock) is skipped instead of taking down the whole list.
    #
    # This builds on the RELEASED ssh-key 0.6.7 (no ssh-key 0.7 fork): our opkssh
    # fork now mints certificates with a real valid_before (= the ID Token exp),
    # which ssh-key 0.6.7 parses fine. Only the old `Valid: forever` certs
    # (valid_before = u64::MAX) needed ssh-key 0.7 (RustCrypto/SSH#504).
    # Wrapped in a function so pipe assembly does not pre-apply the overlay.
    nixpkgs-overlays = { ... }: [
      (final: prev: {
        ssh-agent-mux = prev.ssh-agent-mux.overrideAttrs (_old: rec {
          version = "0.2.0-unstable-2026-08-13";
          src = final.fetchFromGitHub {
            owner = "sini";
            repo = "ssh-agent-mux";
            rev = "8c47a16b2878de0525bbe564a30779ece40694f1";
            hash = "sha256-YnjFMfHlIRN6vfsXiDf+cA9/0vZ132mtIuCvLB/HLHg=";
          };
          cargoDeps = final.rustPlatform.fetchCargoVendor {
            inherit src;
            name = "ssh-agent-mux-${version}-vendor";
            hash = "sha256-UsJUGxs7tn9wGtmjjPIHIO7dy6R5HXhlQ9eg8A3gRbw=";
          };
          patches = [ ];
        });
      })
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.ssh-agent-mux ];
      };
  };
}
