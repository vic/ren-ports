# readme fragment: hosts (order 20, replaces dag.entry* of sini docs/hosts.nix).
{ ren, ... }:
{
  ren.aspects.docs-hosts = {
    at = ren.fleet.sini;
    readme = {
      order = 20;
      text = ''
        ## Hosts

        | Name                                               | Description                                                                                             |      Type   |        Arch    |
        | :------------------------------------------------- | :------------------------------------------------------------------------------------------------------ | :---------: | :------------: |
        | [uplink](modules/hosts/uplink/uplink.nix)          | Ryzen 5950X (16/32) - 128GB - 10gbe - Intel Arc A310 - AV1 Transcoding / Router / k8s control           |    Server   |  x86_64-linux  |
        | [axon-01](modules/hosts/axon-01/axon-01.nix)       | MINISFORUM Venus UM790 Pro - Ryzen 9 7940HS (8/16) - 64GB - 2.5gbe - Radeon 780M - k8s node             |    Server   |  x86_64-linux  |
        | [axon-02](modules/hosts/axon-02/axon-02.nix)       | MINISFORUM Venus UM790 Pro - Ryzen 9 7940HS (8/16) - 64GB - 2.5gbe - Radeon 780M - k8s node             |    Server   |  x86_64-linux  |
        | [axon-03](modules/hosts/axon-03/axon-03.nix)       | MINISFORUM Venus UM790 Pro - Ryzen 9 7940HS (8/16) - 64GB - 2.5gbe - Radeon 780M - k8s node             |    Server   |  x86_64-linux  |
        | [bitstream](modules/hosts/bitstream/bitstream.nix) | GMKtec M6 - Ryzen 5 6600H (8/16) - 64GB - 2.5gbe - Radeon 660M - k8s node                               |    Server   |  x86_64-linux  |
        | [cortex](modules/hosts/cortex/cortex.nix)          | Ryzen 9950X3D (16/32) - 128GB - 10gbe - 7900XTX + 3090TI - Hybrid ML Server/Workstation/VFIO Gaming Rig | Workstation |  x86_64-linux  |
        | [blade](modules/hosts/blade/blade.nix)             | Razer Blade 16 (2023) - NixOS - 32GB ram - RTX 4090 (mobile)                                            |    Laptop   |  x86_64-linux  |
        | [patch](modules/hosts/patch/patch.nix)             | M1 Macbook Air - 16gb / 1tb - macOS Sequoia 15.2                                                        |    Laptop   | aarch64-darwin |

      '';
    };
  };
}
