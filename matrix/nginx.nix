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

      clientMaxBodySize = "100m";

      virtualHosts."${server_name}" = {
        forceSSL = true;
        useACMEHost = "${server_name}";
        kTLS = true;
      };
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "example@thisismyactual.email";
      certs."${server_name}" = {
        webroot = "/var/lib/acme/acme-challenge";
        group = "nginx";
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    environment.persistence."/persistent".directories = [
      "/var/lib/acme"
    ];
  }
