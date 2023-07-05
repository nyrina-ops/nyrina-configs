{
  services.restic.backups.backblaze = {
    initialize = true;

    passwordFile = "/run/secrets/restic/password";
    environmentFile = "/run/secrets/restic/environment_file";
    repository = "b2:nyrina-backups";

    paths = [ "/persistent" ];

    timerConfig = {
      # backup every day
      OnUnitActiveSec = "1d";
    };

    # keep 7 daily, 5 weekly, and 10 annual backups
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-yearly 10"
    ];
  };

  sops.secrets = {
    "restic/password" = {};
    "restic/environment_file" = {};
  };
}
