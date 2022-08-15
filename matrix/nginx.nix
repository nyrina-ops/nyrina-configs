{ config, ... }:

let
  server_name = config.services.dendrite.settings.global.server_name;
in
  {
    services.nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."${server_name}" = {
        forceSSL = true;
        enableACME = true;
        kTLS = true;
      };
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "example@thisismyactual.email";
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    environment.persistence."/persistent".directories = [
      "/var/lib/acme"
    ];
  }
