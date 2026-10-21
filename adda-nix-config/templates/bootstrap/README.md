# NixOS Installation

1. Create live boot ISO USB stick from a downloaded ISO.

   ```sh
   dd bs=4M if=/path/to/iso/file.iso of=/dev/<USB> conv=fsync oflag=direct status=progress
   ```

1. Boot into the UEFI version of the live boot ISO.
   In the boot menu select the entry labeled `UEFI: <Generic?...>`.

1. Enter root shell.

   ```sh
   sudo su
   ```

1. Disable auto-sleep in the DE.

1. Clone the `codeberg:Adda/nixos-config` repository.

   ```sh
   nix-shell -p git --run "git clone https://codeberg.org/Adda/nixos-config"
   cd nixos-config/
   ```

1. Find out what disks are present on the machine.

   ```sh
   lsblk
   ```

1. Prepare the [Disko](https://github.com/nix-community/disko) `/templates/bootstrap/_disko.nix` file for the current machine. See [notes](disko.md) on Disko options.

1. Generate hardware configuration.

   ```sh
   nixos-generate-config --no-filesystems --show-hardware-config > templates/bootstrap/_hardware.nix
   ```

1. Run Disko on the prepared `_disko.nix` file and install the NixOS configuration.

   ### As a sequence of manual steps

   ````
    1. Run the `disko` command.

        ```sh
        nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount modules/hosts/<HOST>/_disko.nix

        ```

    2. Explore the formatted disk to ensure all is correctly formatted and mounted.
        You can verify this by running the following commands:

        ```sh
        mount | grep /mnt
        # Look for mount points and desired partitions.

        # Inspect the create partiions, their labels and flags.
        gparted

        # Explore the created LVM volumes.

        # Physical Volumes.
        pvs
        # Volume Groups.
        vgs
        # Logical Volumes.
        lvs
        ```

    3. If all is well, install the system.
        Build the configuration locally in the machine.

        Copy the entire repository into the `/mnt/etc/nixos/` folder.

          ```sh
          cp . /mnt/etc/nixos/
          ```

        Or, if the machine is too weak to build the whole system configuration, use another machine as a remote
          builder, and locally build only a bootstrapping configuration for now, building only some initial and
          necessary parts.

          Copy the bootstrap configuration into the `/mnt/etc/nixos/` folder.

          ```sh
          cp -r templates/bootstrap/* /mnt/etc/nixos/
          ```

    4. Install the bootstrap configuration with the appropriate host.

      ```sh
      nixos-install --flake /mnt/etc/nixos#<hostName>
      ```
   ````

   <!-- TODO ### Or using `disko-install` -->

1. Configure the installed system.

   ```sh
   nixos-enter

   passwd root
   passwd adda

   nix-shell -p git --run "git clone https://codeberg.org/Adda/nixos-config ~/.nixos-config"
   cd ~/.nixos-config/
   ```

   Copy `_disko.nix`, `_hardware.nix` to `~/.nixos-config` and configure the new host according to `/etc/nixos/`.

   - Generating secrets and keys
     - Generate SSH key-pair

       ```sh
       ssh-keygen -t ed25519 -a 100 -C "adda@HOST"
       ```

     - Generate GPG key-pair

       Generate the key-pair.

       ```sh
       gpg --full-generate-key
       # If RSA, at least 4096 bits.
       ```

       List the secret keys. Look for the `sec` section.

       ```sh
       gpg --list-secret-keys --keyid-format LONG
       ```

       ```sh
       gpg --armor --export <GPG_KEY_SEC_ID>
       ```

     - Generate SOPS/Age keys.
       `-pq` in `age-keygen` options generates post-quantum secure encryption keys.

       ```sh
       mkdir --parents $HOME/.config/sops/age/
       nix-shell --packages ssh-to-age --run "ssh-to-age -private-key -i $HOME/.ssh/id_ed25519 > $HOME/.config/sops/age/keys.txt"
       nix-shell --packages age --run "age-keygen -y -pq $HOME/.config/sops/age/keys.txt"
       nix-shell --packages ssh-to-age --run "ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub"
       ```

       Add the generated key to `.sops.yaml` under a new name `<USER>-<HOST>`.

1. Reboot to the installed system.
   You can now unplug the live boot USB stick.

   ```sh
   reboot
   ```

1. If the bootstrap flake was built, setup a remote buider to build the full configuration.
   Make the local machine not require signatures for the closure:
   Add `nix.settings.requires-sigs = false;` and `nix.settings.trusted-users=["adda" "@wheel" "root"];`

Connect to/from a remote builder.

On the local machine:

```sh
sudo tailscale up --ssh
```

On a remote builder:

```sh
sshfs adda@HOST-nixos:/ /mnt/
cd /mnt/home/adda/.nixos-config

nix build .#nixosConfigurations.HOST-nixos.config.system.build.toplevel
nix copy --to HOST-nixos ./result
# Or
nix-copy-closure --to HOST-nixos ./result
# Followed on the local machine by:
nixos-rebuild boot --flake .


# Or
nixos-rebuild boot --flake .#HOST-nixos --target-host HOST-nixos --sudo --ask-sudo-password
```

# `nixos-enter` with Btrfs

```
sudo su
mount -t btrfs -o subvol=root /dev/sda2 /mnt
mkdir -p /mnt/{home,nix,tmp,boot/efi}
mount -t btrfs -o subvol=home /dev/pool-ssd/root /mnt/home
mount -t btrfs -o subvol=nix /dev/pool-ssd/root /mnt/nix
mount -t btrfs -o subvol=tmp /dev/pool-ssd/root /mnt/tmp
mount /dev/sdb2 /mnt/boot/efi
```

# Update sops secrets for new machines with new sops keys

On a machine that has already had secrets access set up run the update script.

```sh
just sops-update
```

# Services to log into

- atuin CLI

  ```sh
  atuin login
  ```

# Check which disk is mapped to which partition label

See `/dev/disk/by-partlabel/*`.
