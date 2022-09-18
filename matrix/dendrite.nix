{ config, lib, pkgs, ... }:

let
  server_name = config.services.dendrite.settings.global.server_name;
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

    environment.systemPackages = [
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
  }
