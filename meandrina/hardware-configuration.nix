{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub = {
    device = "/dev/vda";
    # FIXME: THIS IS A NASTY HACK LOL
    # the grub config generator gets REALLY confused about /nix and /boot being bind-mounted from /persistent
    # i dont really know why this works honestly but the first character gets replaced with a /
    # and the literal /nix/store is special-cased so i cant use that
    fsIdentifier = "provided";
    storePath = "#nix/store";
  };
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" ];
  boot.initrd.kernelModules = [ "nvme" ];

  fileSystems."/" = { device = "none"; fsType = "tmpfs"; options = [ "defaults" "mode=755" ]; };
  fileSystems."/persistent" = { device = "/dev/vda1"; fsType = "ext4"; neededForBoot = true; };

  environment.persistence."/persistent".directories = [
    "/nix"
    "/boot"
  ];
}
