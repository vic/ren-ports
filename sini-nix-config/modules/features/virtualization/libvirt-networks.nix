# libvirt: stale secrets-encryption-key repair + default network definitions.
{ ... }:
{
  ren.aspects.virtualization-libvirt.nixos =
    { pkgs, ... }:
    let
    primaryNetwork = pkgs.writeText "default-network.xml" ''
      <network>
        <name>default</name>
        <uuid>d5ee6d97-4d4b-4e05-87bb-69b682182cf4</uuid>
        <forward mode='nat'>
          <nat>
            <port start='1024' end='65535'/>
          </nat>
        </forward>
        <bridge name='virbr0' stp='on' delay='0'/>
        <ip address='192.168.122.1' netmask='255.255.255.0'>
          <dhcp>
            <range start='192.168.122.2' end='192.168.122.254'/>
          </dhcp>
        </ip>
      </network>
    '';

    primarybridgeNetwork = pkgs.writeText "default-bridge.xml" ''
      <network>
        <name>default-bridge</name>
        <uuid>6dea79f2-1512-40c6-a2a3-ed0b15a9c72d</uuid>
        <forward mode='bridge'/>
        <bridge name='virbr1'/>
      </network>
    '';
    in
    {
    # libvirt 12.x ships an upstream drop-in (10-secret.conf) that loads
    # /var/lib/libvirt/secrets/secrets-encryption-key via
    # LoadCredentialEncrypted, i.e. encrypted against the host key in
    # /var/lib/systemd/credential.secret. We persist that host key (see
    # impermanence), but a blob written before the key was persisted — or
    # any future host-key loss — leaves an undecryptable blob that libvirtd
    # rejects with status=243/CREDENTIALS. virt-secret-init-encryption only
    # generates the key when absent (ConditionPathExists=!...), so it never
    # repairs a stale one. Drop a stale blob so it gets regenerated.
    systemd.services.virt-secret-init-encryption-repair = {
      before = [
        "virt-secret-init-encryption.service"
        "libvirtd.service"
      ];
      requiredBy = [ "libvirtd.service" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        key=/var/lib/libvirt/secrets/secrets-encryption-key
        if [ -e "$key" ] && \
           ! ${pkgs.systemd}/bin/systemd-creds decrypt \
               --name=secrets-encryption-key "$key" - >/dev/null 2>&1; then
          echo "removing undecryptable libvirt secrets-encryption-key for regeneration"
          rm -f "$key"
        fi
      '';
    };

    systemd.services.libvirt-networks = {
      description = "Setup libvirt networks";
      after = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        sleep 5

        if ! ${pkgs.libvirt}/bin/virsh net-list --all | grep -q "default "; then
          ${pkgs.libvirt}/bin/virsh net-define ${primaryNetwork}
        fi

        if ! ${pkgs.libvirt}/bin/virsh net-list --all | grep -q "default-bridge"; then
          ${pkgs.libvirt}/bin/virsh net-define ${primarybridgeNetwork}
        fi

        ${pkgs.libvirt}/bin/virsh net-autostart default 2>/dev/null || true
        ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true

        ${pkgs.libvirt}/bin/virsh net-autostart default-bridge 2>/dev/null || true
        ${pkgs.libvirt}/bin/virsh net-start default-bridge 2>/dev/null || true
      '';
    };
    };
}
