{ config, lib, ... }:

let
  server_name = config.services.dendrite.settings.global.server_name;
in
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
            private_key = "$CREDENTIALS_DIRECTORY/private_key";

            dns_cache = {
              enabled = true;
              cache_size = 4096;
              cache_lifetime = "600s";
            };

            presence = {
              enable_inbound = true;
              enable_outbound = true;
            };
          };

          # 'msc2444': Peeking over federation - https://github.com/matrix-org/matrix-doc/pull/2444
          # 'msc2753': Peeking via /sync - https://github.com/matrix-org/matrix-doc/pull/2753
          # 'msc2836': Threading - https://github.com/matrix-org/matrix-doc/pull/2836
          # 'msc2946': Spaces Summary - https://github.com/matrix-org/matrix-doc/pull/2946
          mscs.mscs = [
            "msc2836"
            "msc2946"
          ];

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
          {
            name = "matrix-media-repo";
            ensurePermissions = {
              "DATABASE \"matrix-media-repo\"" = "ALL PRIVILEGES";
            };
          }
        ];

        ensureDatabases = [
          "dendrite"
          "matrix-media-repo"
        ];
      };

      nginx = {
        enable = true;

        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        virtualHosts."${server_name}" = {
          forceSSL = true;
          enableACME = true;
          kTLS = true;

          locations = {
            "= /.well-known/matrix/server".extraConfig = ''
              add_header Content-Type application/json;
              return 200 '{ "m.server": "${server_name}:443" }';
            '';

            "= /.well-known/matrix/client".extraConfig = ''
              add_header Content-Type application/json;
              add_header Access-Control-Allow-Origin *;
              return 200 '{ "m.homeserver": { "base_url": "https://${server_name}" } }';
            '';

            "/_matrix".proxyPass = "http://127.0.0.1:8008";

            "/_matrix/media".proxyPass = "http://127.0.0.1:8000";
          };
        };
      };

      matrix-media-repo = {
        enable = true;
        environmentFile = "/run/secrets/matrix-media-repo/environment_file";
        settings = {
          homeservers = [
            {
              name = server_name;
              csApi = "https://${server_name}/";
            }
          ];
          database.postgres = "postgresql:///matrix-media-repo?host=/run/postgresql";
          datastores = [
            {
              type = "s3";
              opts = {
                tempPath = "";
                endpoint = "s3.us-west-004.backblazeb2.com";
                accessKeyId = "$ACCESS_KEY_ID";
                accessSecret = "$ACCESS_SECRET";
                ssl = true;
                bucketName = "nyrina-media";
              };
            }
          ];
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
      "matrix-media-repo/environment_file" = {};
    };

    environment.persistence."/persistent".directories = [
      "/var/lib/postgresql"
      "/var/lib/acme"
    ];
  }
