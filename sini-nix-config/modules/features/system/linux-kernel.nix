# linux-kernel: CachyOS kernel selection.
# Ported from main:modules/_legacy/core/linux-kernel.nix.
{ ren, lib, inputs, ... }:
{
  # den settings.core.system.linux-kernel.*; flat field named after the aspect.
  ren.kinds.machine.system-linux-kernel = ren.lib.opt (lib.types.submodule {
    options = {
      channel = lib.mkOption {
        type = lib.types.enum [
          "lts"
          "latest"
        ];
        default = "latest";
        description = "CachyOS kernel release channel";
      };
      optimization = lib.mkOption {
        type = lib.types.enum [
          "server"
          "zen4"
          "x86_64-v4"
        ];
        default = "server";
        description = "CachyOS kernel optimization target";
      };
    };
  }) { };

  ren.aspects.system-linux-kernel = {
    nixpkgs-overlays = [
      # lld 21 built by GCC 16 corrupts `ld -r` output, so objtool rejects every
      # multi-object LTO module (nixpkgs#571232). lld 22 carries the upstream fix
      # (llvm/llvm-project@905a88b); build the kernels with it.
      (
        final: prev:
        inputs.nix-cachyos-kernel.overlays.default final (
          prev.extend (_: p: { llvmPackages = p.llvmPackages_22; })
        )
      )

      # 7.2.5 added a memchr() bounds check to gud_connector_add_tv_mode(); Clang
      # LTO can't prove num_modes <= GUD_CONNECTOR_TV_MODE_MAX_NUM, so
      # FORTIFY_SOURCE emits __read_overflow and every -lto variant fails to link.
      # Still unfixed in 7.2.6. Nothing in the fleet is a USB display.
      (_final: prev: {
        cachyosKernels = lib.mapAttrs (
          _: v:
          if v ? kernel then
            v.extend (
              _: prevPkgs: {
                kernel = prevPkgs.kernel.override {
                  structuredExtraConfig.DRM_GUD = lib.kernel.no;
                };
              }
            )
          else
            v
        ) prev.cachyosKernels;
      })
    ];

    nixos =
      { host, pkgs, ... }:
      let
        cfg = host.system-linux-kernel;
        kernelName =
          if cfg.optimization == "server" then
            "linuxPackages-cachyos-server-lto"
          else
            "linuxPackages-cachyos-${cfg.channel}-lto-${cfg.optimization}";
      in
      {
        boot.kernelPackages =
          if pkgs ? cachyosKernels && pkgs.cachyosKernels ? ${kernelName} then
            pkgs.cachyosKernels.${kernelName}
          else if pkgs ? ${kernelName} then
            pkgs.${kernelName}
          else
            pkgs.linuxPackages_latest;
      };
  };
}
