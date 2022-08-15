{ config, ... }:

let
  server_name = config.services.dendrite.settings.global.server_name;
in
  {
    imports = [
      ./nginx.nix
      ./postgresql.nix
    ];

    services = {
      postgresql = {
        ensureUsers = [
          {
            name = "matrix-media-repo";
            ensurePermissions = {
              "DATABASE \"matrix-media-repo\"" = "ALL PRIVILEGES";
            };
          }
        ];

        ensureDatabases = [ "matrix-media-repo" ];
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

      nginx.virtualHosts."${server_name}".locations."/_matrix/media".proxyPass = "http://127.0.0.1:8000";
    };

    sops.secrets."matrix-media-repo/environment_file" = {};
  }
