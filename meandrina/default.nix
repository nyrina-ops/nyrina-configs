{
  imports = [
    ../common.nix
    ./hardware-configuration.nix
    ./networking.nix
  ];

  networking.hostName = "meandrina";
  sops.defaultSopsFile = ../secrets/meandrina.yaml;
  services.dendrite.settings.global.server_name = "meandrina.thekitten.space";
}
