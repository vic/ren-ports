# Disko Configuration

- Use `type = "filesystem";` (with `format = "vfat";` or `format = "ext4";`, etc.) when you want a simple, flat partition (like `/boot/efi` or a basic ext4 root).
- Use `type = "btrfs"` whenever you want to use Btrfs and take advantage of Disko's specific filesystem options such as `subvolumes`, etc.
