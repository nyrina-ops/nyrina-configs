{ config, lib, pkgs, ... }:

let
  server_name = config.services.dendrite.settings.global.server_name;

  database_config = {
    connection_string = "postgresql:///dendrite?host=/run/postgresql";
    max_open_conns = 10;
    max_idle_conns = 5;
  };
in
  {
    imports = [
      ./nginx.nix
      ./postgresql.nix
    ];

    services = {
      dendrite = {
        enable = true;

        loadCredential = [
          "private_key:/run/secrets/dendrite/private_key"
        ];

        environmentFile = "/run/secrets/dendrite/environment_file";

        settings = {
          global = {
            private_key = "$CREDENTIALS_DIRECTORY/private_key";

            # preserve across restarts
            jetstream.storage_path = "/var/lib/dendrite/";

            dns_cache = {
              enabled = true;
              cache_size = 4096;
              cache_lifetime = "600s";
            };

            presence = {
              enable_inbound = true;
              enable_outbound = true;
            };

            cache.max_size_estimated = "16gb";
          };

          # 'msc2444': Peeking over federation - https://github.com/matrix-org/matrix-doc/pull/2444
          # 'msc2753': Peeking via /sync - https://github.com/matrix-org/matrix-doc/pull/2753
          # 'msc2836': Threading - https://github.com/matrix-org/matrix-doc/pull/2836
          # 'msc2946': Spaces Summary - https://github.com/matrix-org/matrix-doc/pull/2946
          mscs.mscs = [
            "msc2836"
            "msc2946"
          ];

          federation_api.key_perspectives = [
            {
              server_name = "matrix.org";
              keys = [
                { key_id = "ed25519:auto"; public_key = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw"; }
                { key_id = "ed25519:a_RXGa"; public_key = "l8Hft5qXKn1vfHrg3p4+W8gELQVo8N13JkluMfmn2sQ"; }
              ];
            }
          ];

          client_api.registration_shared_secret = "$REGISTRATION_SHARED_SECRET";

          sync_api.search = {
            enabled = true;
            index_path = "/var/lib/dendrite/searchindex";
          };

          app_service_api.database = database_config;
          federation_api.database = database_config;
          key_server.database = database_config;
          media_api.database = database_config;
          mscs.database = database_config;
          room_server.database = database_config;
          sync_api.database = database_config;
          user_api.account_database = database_config;
          user_api.device_database = database_config;
        };
      };

      postgresql = {
        ensureUsers = [
          {
            name = "dendrite";
            ensurePermissions = {
              "DATABASE dendrite" = "ALL PRIVILEGES";
            };
          }
        ];

        ensureDatabases = [ "dendrite" ];
      };

      nginx.virtualHosts."${server_name}".locations = {
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
      };
    };

    systemd.services.dendrite.after = [ "postgresql.service" ];

    sops.secrets = {
      "dendrite/private_key" = {};
      "dendrite/environment_file" = {};
    };

    environment = {
      systemPackages = [
        (pkgs.writeShellScriptBin "new-matrix-user" ''
          set -e

          username="$1"
          if [[ -z "$username" ]]; then
            echo "usage: new-matrix-user <username>" >&2
            exit 1
          fi

          password="$(${pkgs.pwgen}/bin/pwgen -s 32 1)"

          ${pkgs.dendrite}/bin/create-account \
            --config /run/dendrite/dendrite.yaml \
            --url http://localhost:8008 \
            --username "$username" \
            --passwordstdin <<<"$password"

          printf 'password: %s' "$password"
        '')
      ];

      persistence."/persistent".directories = [
        "/var/lib/private/dendrite"
      ];
    };
  }
