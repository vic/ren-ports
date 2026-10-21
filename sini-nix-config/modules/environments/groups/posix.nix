# Group instances: POSIX groups (Unix permissions).
{ ren, ... }:
{
  ren.group.wheel = {
    labels = [ "posix" ];
    description = "Sudo access";
    members = [
      ren.group.admins
    ];
  };
  ren.group.audio = {
    labels = [ "posix" ];
    description = "Audio device access";
    members = [
      ren.group.workstation-access
    ];
  };
  ren.group.sound = {
    labels = [ "posix" ];
    description = "Sound device access";
    members = [
      ren.group.workstation-access
    ];
  };
  ren.group.video = {
    labels = [ "posix" ];
    description = "Video device access";
    members = [
      ren.group.workstation-access
    ];
  };
  ren.group.networkmanager = {
    labels = [ "posix" ];
    description = "NetworkManager control";
    members = [
      ren.group.workstation-access
    ];
  };
  ren.group.input = {
    labels = [ "posix" ];
    description = "Input device access";
    members = [
      ren.group.workstation-access
    ];
  };
  ren.group.tty = {
    labels = [ "posix" ];
    description = "TTY access";
    members = [
      ren.group.workstation-access
    ];
  };
  ren.group.podman = {
    labels = [ "posix" ];
    description = "Container runtime access";
    members = [
      ren.group.workstation-access
    ];
  };
  ren.group.media = {
    labels = [ "posix" ];
    description = "Media files access";
    members = [
      ren.group.workstation-access
    ];
  };
  ren.group.gamemode = {
    labels = [ "posix" ];
    description = "GameMode access";
    members = [
      ren.group.workstation-access
    ];
  };
  ren.group.render = {
    labels = [ "posix" ];
    description = "GPU render access";
    members = [
      ren.group.workstation-access
    ];
  };
  ren.group.libvirtd = {
    labels = [ "posix" ];
    description = "VM management access";
    members = [
      ren.group.admins
    ];
  };
  ren.group.kvm = {
    labels = [ "posix" ];
    description = "KVM hypervisor access";
    members = [
      ren.group.admins
    ];
  };
}
