{ config, pkgs, ... }:

let
  server_name = config.services.dendrite.settings.global.server_name;
in
  {
    imports = [
      ./postgresql.nix
    ];

    services = {
      postgresql = {
        ensureUsers = [
          {
            name = "matrix-appservice-discord";
            ensurePermissions = {
              "DATABASE \"matrix-appservice-discord\"" = "ALL PRIVILEGES";
            };
          }
        ];

        ensureDatabases = [ "matrix-appservice-discord" ];
      };

      matrix-appservice-discord = {
        enable = true;
        environmentFile = "/run/secrets/matrix-appservice-discord/environment_file";
        url = "http://127.0.0.1:${toString config.services.matrix-appservice-discord.port}";
        settings = {
          bridge = {
            domain = server_name;
            homeserverUrl = "https://${server_name}";
            disableJoinLeaveNotifications = true;
            disableInviteNotifications = true;
            disableRoomTopicNotifications = true;
            adminMxid = "@kity:kity.wtf";
          };
          channel.namePattern = ":name";
          database.connString = "postgresql:///matrix-appservice-discord?host=/run/postgresql";
          # room.defaultVisibility = "private";
          auth.usePrivilegedIntents = true;
        };
      };

      dendrite.settings.app_service_api.config_files = [
        "/var/lib/dendrite/discord/discord-registration.yaml"
      ];
    };

    systemd.services.matrix-appservice-discord.serviceConfig.User = "matrix-appservice-discord";

    systemd.services.matrix-appservice-discord-bindfs = {
      after = [ "matrix-appservice-discord.service" ];
      wantedBy = [ "matrix-appservice-discord.service" "dendrite.service" ];
      before = [ "dendrite.service" ];
      script = ''
        mkdir -p /var/lib/dendrite/discord
        ${pkgs.bindfs}/bin/bindfs -u dendrite -g dendrite -p 0400,u+D \
          /var/lib/matrix-appservice-discord \
          /var/lib/dendrite/discord
      '';
      serviceConfig.Type = "forking";
    };

    nixpkgs.overlays = [
      (self: super: {
        matrix-appservice-discord = super.matrix-appservice-discord.overrideAttrs (old: {
          patches = [
            (super.fetchpatch {
              url = "https://patch-diff.githubusercontent.com/raw/matrix-org/matrix-appservice-discord/pull/842.patch";
              sha256 = "sha256-XPTbzZgRJzwiRs817LP28/SDXEMyNdt82R4OAAZoHBI=";
            })
          ];

          postPatch = ''
            substituteInPlace src/discordas.ts \
              --replace 'sender_localpart: "_discord_bot"' 'sender_localpart: "_discord"'
          '';
        });
      })
    ];

    sops.secrets."matrix-appservice-discord/environment_file" = {};
  }
