# K3s HA: keepalived VRRP floating the kube-apiserver VIP, plus Longhorn host requirements.
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
{
  ren.aspects.svc-k3s.nixos =
    { k3s-nodes, config, pkgs, host, ... }:
    let
      cluster = ren.helpers.clusterOf host;
      vip = ren.helpers.getAssignment cluster "kube-apiserver-vip";
      clusterNodes = lib.filter (n: n.clusterName == host.svc-k3s.clusterName) k3s-nodes;
      sortedNodes = builtins.sort (a: b: a.hostname < b.hostname) clusterNodes;
      nodeIdx = lib.lists.findFirstIndex (node: node.hostname == host.name) null sortedNodes;
      nodeId =
        assert lib.assertMsg (nodeIdx != null) ''
          k3s aspect failed to find host "${host.name}" in cluster peers.
          Available: ${lib.concatStringsSep ", " (map (n: n.hostname) sortedNodes)}
        '';
        nodeIdx;
    in
    lib.mkIf (cluster != null) {
      services = {
        # Keepalived VRRP, floats the kube-apiserver VIP across server nodes
        keepalived = {
          enable = true;
          vrrpScripts.check_k3s = {
            script = "${lib.getExe pkgs.netcat} -z 127.0.0.1 6443";
            interval = 2;
            weight = -20;
            fall = 2;
            rise = 2;
          };
          vrrpInstances.k3s = {
            state = if nodeId == 0 then "MASTER" else "BACKUP";
            interface = "enp2s0";
            virtualRouterId = 51;
            priority = 100 - nodeId;
            virtualIps = [
              # /32: a /<subnet> VIP adds a connected route with src = VIP, so
              # whichever node holds it sources its LAN traffic (10.10.10.0/24)
              # from the VIP instead of its own address.
              { addr = "${vip}/32"; }
            ];
            trackScripts = [ "check_k3s" ];
          };
        };

        # Required for Longhorn
        openiscsi = {
          enable = true;
          name = "iqn.2016-04.com.open-iscsi:${config.networking.fqdn}";
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/longhorn 0750 root root -"
        "L+ /usr/local/bin/iscsiadm - - - - ${pkgs.openiscsi}/bin/iscsiadm"
        # Longhorn's filesystem trim nsenters the host and runs fstrim by name.
        "L+ /usr/local/bin/fstrim - - - - ${pkgs.util-linux}/bin/fstrim"
      ];

      systemd.services.multipathd.enable = lib.mkForce false;
    };
}
