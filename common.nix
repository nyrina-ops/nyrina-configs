{ ... }: {
  imports = [
    ./matrix
  ];

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGfEjFxICM8XxLy46DBGKFpb8qGelsGpNWBV8e0R0CpD ash@boson"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILjtW4fdEFViHXGQq0zQxB2QDxnqTHefAJd75uft7k9C cardno:20 674 870"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDDZ9/PV++mSSGXeRbS/Pd4Df81cv/7Ds8WlQGmI2yth cardno:12 286 835"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDv9V3siJ54ralGYL0Fw/sZLSfW8YhMvdfHsvXy15fFe+xwWyBnNRTKjVg5I0tIWIfiK/go+qteRV2w6Zi+tlJ+96nggDhiASCXA9MCtYxtXxF4TTbE2o14ss7p2qWrhWM3L0of9BVRV7neNFkmnVnsV7+3H2kk1R7bLyQZzdEKnNrbw4xg7ktgP911j3mp/CmYzkS3Ckf3J2wNWHMoWT/Y1f+owQfS6gXIjJoAW9bX28TeCKQezi0ujfK4SXWrhIQjtkNFqrza5Tk8eOTWd0s7oMqco65MsJ36nIFC918N/Ga6m+DJWmBSI1Pepr3ZWCjQq8Da6Iv1PPvK5/cLSxgEmIz4Mio+BSWF9eKSlBiMWTONnI1uZ4w4zrqW9tI0yjRQlaELlt5Z9QHMRLMGBgli7/H52xRPb6OI/2hpokT/7QzR/MCotEe8GPbYVAWYA/pgl5z3S8FCLQieFax+IAgLH9MVX60ytuVZRvrXRA7jza2ZLZzIbzAgc/AwYLTymnE= anbl@ananas"
  ];

  users.mutableUsers = false;

  environment.persistence."/persistent" = {
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  sops = {
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };

  system.stateVersion = "22.05";
}
