{ config, ... }:

let
  server_name = config.services.dendrite.settings.global.server_name;
in
  {
    services = {
      matrix-sliding-sync = {
        enable = true;
        environmentFile = "/run/secrets/sliding-sync/environment_file";
        settings = {
          SYNCV3_SERVER = "https://${server_name}";
        };
      };

      nginx.virtualHosts."${server_name}".locations = {
        "~ ^/(client/|_matrix/client/unstable/org.matrix.msc3575/sync)" = {
          proxyPass = "http://${config.services.matrix-sliding-sync.settings.SYNCV3_BINDADDR}";
        };
      };
    };
  }
