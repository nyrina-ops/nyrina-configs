{ config, pkgs, ... }:

let
  server_name = config.services.dendrite.settings.global.server_name;
in
  {
    services.nginx.virtualHosts."cinny.${server_name}" = {
      forceSSL = true;
      useACMEHost = "${server_name}";
      kTLS = true;

      root = pkgs.cinny.override {
        conf = {
          defaultHomeserver = 0;
          homeserverList = [ server_name ];
        };
      };

      locations."/".extraConfig = ''
        add_header X-Frame-Options SAMEORIGIN;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Content-Security-Policy "frame-ancestors 'none'";
      '';
    };

    security.acme.certs."${server_name}".extraDomainNames = [
      "cinny.${server_name}"
    ];
  }
