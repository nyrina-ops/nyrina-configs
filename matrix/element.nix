{ config, pkgs, ... }:

let
  server_name = config.services.dendrite.settings.global.server_name;
in
  {
    services.nginx.virtualHosts."element.${server_name}" = {
      forceSSL = true;
      useACMEHost = "${server_name}";
      kTLS = true;

      root = pkgs.element-web.override {
        conf = {
          default_server_config."m.homeserver" = {
            "base_url" = "https://${server_name}";
            "server_name" = "${server_name}";
          };
          show_labs_settings = true;
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
      "element.${server_name}"
    ];
  }
