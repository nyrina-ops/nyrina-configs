{
  services.postgresql.enable = true;

  environment.persistence."/persistent".directories = [
    "/var/lib/postgresql"
  ];
}
