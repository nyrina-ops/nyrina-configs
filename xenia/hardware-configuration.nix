# adapted from https://github.com/NixOS/nixpkgs/pull/119856
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_pci" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = { device = "none"; fsType = "tmpfs"; options = [ "defaults" "mode=755" ]; };
  fileSystems."/nix" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/disk/by-label/ESP"; fsType = "vfat"; };
  fileSystems."/persistent" = { device = "/dev/disk/by-label/persistent"; fsType = "ext4"; neededForBoot = true; };

  swapDevices = [ ];

  boot.kernelParams = [
    "nvme.shutdown_timeout=10"
    "nvme_core.shutdown_timeout=10"
    "libiscsi.debug_libiscsi_eh=1"
    "crash_kexec_post_notifiers"

    # VNC console
    "console=tty1"

    # aarch64-linux
    "console=ttyAMA0,115200"
  ];

  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub = {
    version = 2;
    device = "nodev";
    splashImage = null;
    extraConfig = ''
      serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
      terminal_input --append serial
      terminal_output --append serial
    '';
    efiInstallAsRemovable = true;
    efiSupport = true;
  };

  # https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/configuringntpservice.htm#Configuring_the_Oracle_Cloud_Infrastructure_NTP_Service_for_an_Instance
  networking.timeServers = [ "169.254.169.254" ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
