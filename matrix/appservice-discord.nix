{ config, lib, pkgs, ... }:

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
            disablePresence = true; # TODO: remove this when https://github.com/matrix-org/dendrite/issues/2752 is fixed
            adminMxid = "@kity:kity.wtf";
          };
          channel.namePattern = ":name";
          database = {
            connString = "postgresql:///matrix-appservice-discord?host=/run/postgresql";
            filename = null;
          };
          # room.defaultVisibility = "private";
          auth.usePrivilegedIntents = true;
        };
      };

      dendrite.settings.app_service_api.config_files = [
        "/var/lib/dendrite/discord/discord-registration.yaml"
      ];
    };

    systemd = {
      services.matrix-appservice-discord.serviceConfig.User = "matrix-appservice-discord";

      mounts = [
        {
          before = [ "dendrite.service" ];
          wantedBy = [ "dendrite.service" ];
          after = [ "matrix-appservice-discord.service" ];
          bindsTo = [ "matrix-appservice-discord.service" ];

          type = "fuse.bindfs";
          what = "/var/lib/matrix-appservice-discord";
          where = "/var/lib/private/dendrite/discord";
          # avoid a dependency cycle by adding noauto and nofail; otherwise it will
          # implicitly get a Before= dependency on `local-fs.target` and we don't want that
          options = "noauto,nofail,force-user=dendrite,force-group=dendrite,perms=0000:u+rD";
        }
      ];
    };

    system.fsPackages = [ pkgs.bindfs ];

    # need static user for matrix-appservice-discord-bindfs.service
    # otherwise it won't be able to set the correct permissions,
    # since dendrite.service isn't started yet
    users = {
      users.dendrite = {
        isSystemUser = true;
        group = "dendrite";
      };

      groups.dendrite = {};
    };

    nixpkgs.overlays = [
      (self: super: {
        matrix-appservice-discord = super.matrix-appservice-discord.overrideAttrs (old: {
          postPatch = ''
            substituteInPlace src/discordas.ts \
              --replace 'sender_localpart: "_discord_bot"' 'sender_localpart: "_discord"'
          '';
        });
      })
    ];

    sops.secrets."matrix-appservice-discord/environment_file" = {};
  }
