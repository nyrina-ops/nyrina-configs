{ lib, ... }:

{
  services = {
    dendrite = {
      enable = true;

      loadCredential = [
        "private_key:/run/secrets/dendrite/private_key"
      ];

      environmentFile = "/run/secrets/dendrite/registration_secret";

      settings = {
        global = {
          server_name = "meandrina.thekitten.space";
          private_key = "$CREDENTIALS_DIRECTORY/private_key";

          dns_cache = {
            enabled = true;
            cache_size = 4096;
            cache_lifetime = "600s";
          };
        };

        client_api.registration_shared_secret = "$REGISTRATION_SHARED_SECRET";

        app_service_api.database.connection_string = "postgresql:///dendrite?host=/run/postgresql";
        federation_api.database.connection_string = "postgresql:///dendrite?host=/run/postgresql";
        key_server.database.connection_string = "postgresql:///dendrite?host=/run/postgresql";
        media_api.database.connection_string = "postgresql:///dendrite?host=/run/postgresql";
        mscs.database.connection_string = "postgresql:///dendrite?host=/run/postgresql";
        room_server.database.connection_string = "postgresql:///dendrite?host=/run/postgresql";
        sync_api.database.connection_string = "postgresql:///dendrite?host=/run/postgresql";
        user_api.account_database.connection_string = "postgresql:///dendrite?host=/run/postgresql";
        user_api.device_database.connection_string = "postgresql:///dendrite?host=/run/postgresql";
      };
    };

    postgresql = {
      enable = true;

      ensureUsers = [
        {
          name = "dendrite";
          ensurePermissions = {
            "DATABASE dendrite" = "ALL PRIVILEGES";
          };
        }
      ];

      ensureDatabases = [
        "dendrite"
      ];
    };

    nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."meandrina.thekitten.space" = {
        forceSSL = true;
        enableACME = true;
        kTLS = true;

        locations = {
          "= /.well-known/matrix/server".extraConfig = ''
            add_header Content-Type application/json;
            return 200 '{ "m.server": "meandrina.thekitten.space:443" }';
          '';

          "= /.well-known/matrix/client".extraConfig = ''
            add_header Content-Type application/json;
            add_header Access-Control-Allow-Origin *;
            return 200 '{ "m.homeserver": { "base_url": "https://meandrina.thekitten.space"} }';
          '';

          "/_matrix" = {
            proxyPass = "http://127.0.0.1:8008";
          };
        };
      };
    };
  };

  systemd.services.dendrite.after = [ "postgresql.service" ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "example@thisismyactual.email";
  };

  sops.secrets = {
    "dendrite/private_key" = {};
    "dendrite/registration_secret" = {};
  };

  environment.persistence."/persistent".directories = [
    "/var/lib/postgresql"
    "/var/lib/acme"
  ];
}
