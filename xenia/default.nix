{
  imports = [
    ../common.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "xenia";
  sops.defaultSopsFile = ../secrets/xenia.yaml;
  services.dendrite.settings.global.server_name = "nyrina.link";
}
