# derived from https://nixos.wiki/wiki/Matrix#Coturn_with_Synapse
{ config, lib, ... }:

let
  server_name = config.services.dendrite.settings.global.server_name;
in
  {
    services = {
      coturn = rec {
        enable = true;
        no-cli = true;
        no-tcp-relay = true;
        min-port = 49000;
        max-port = 50000;
        use-auth-secret = true;
        static-auth-secret-file = "/run/secrets/coturn/static_auth_secret";
        realm = "turn.${server_name}";
        cert = "${config.security.acme.certs.${realm}.directory}/full.pem";
        pkey = "${config.security.acme.certs.${realm}.directory}/key.pem";
        extraConfig = ''
          # TODO: make this configurable per machine or auto-discover
          external-ip=129.153.55.114/10.0.0.85
          # makes the voip tester happy
          # technically not spec compliant behavior?
          # idk why coturn works without this on another machine with public ipv4 assigned directly
          allocation-default-address-family=keep

          verbose
          # ban private IP ranges
          no-multicast-peers
          denied-peer-ip=0.0.0.0-0.255.255.255
          denied-peer-ip=10.0.0.0-10.255.255.255
          denied-peer-ip=100.64.0.0-100.127.255.255
          denied-peer-ip=127.0.0.0-127.255.255.255
          denied-peer-ip=169.254.0.0-169.254.255.255
          denied-peer-ip=172.16.0.0-172.31.255.255
          denied-peer-ip=192.0.0.0-192.0.0.255
          denied-peer-ip=192.0.2.0-192.0.2.255
          denied-peer-ip=192.88.99.0-192.88.99.255
          denied-peer-ip=192.168.0.0-192.168.255.255
          denied-peer-ip=198.18.0.0-198.19.255.255
          denied-peer-ip=198.51.100.0-198.51.100.255
          denied-peer-ip=203.0.113.0-203.0.113.255
          denied-peer-ip=240.0.0.0-255.255.255.255
          denied-peer-ip=::1
          denied-peer-ip=64:ff9b::-64:ff9b::ffff:ffff
          denied-peer-ip=::ffff:0.0.0.0-::ffff:255.255.255.255
          denied-peer-ip=100::-100::ffff:ffff:ffff:ffff
          denied-peer-ip=2001::-2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
          denied-peer-ip=2002::-2002:ffff:ffff:ffff:ffff:ffff:ffff:ffff
          denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
          denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        '';
      };

      dendrite.settings.client_api.turn = with config.services.coturn; {
        turn_uris = [
          "turn:${realm}:${toString listening-port}?transport=udp"
          "turn:${realm}:${toString listening-port}?transport=tcp"
          "turns:${realm}:${toString tls-listening-port}?transport=udp"
          "turns:${realm}:${toString tls-listening-port}?transport=tcp"
        ];
        turn_shared_secret = "$TURN_SHARED_SECRET";
        turn_user_lifetime = "5m";
      };
    };

    networking.firewall = with config.services.coturn; let
      range = [ { from = min-port; to = max-port; } ];
      ports = [ listening-port tls-listening-port ];
    in {
      allowedUDPPortRanges = range;
      allowedUDPPorts = ports;
      allowedTCPPortRanges = range;
      allowedTCPPorts = ports;
    };

    security.acme.certs.${config.services.coturn.realm} = {
      webroot = "/var/lib/acme/acme-challenge";
      # this annoyingly soft-requires a zerossl cert because of chromium's webrtc library
      # https://matrix-org.github.io/synapse/latest/turn-howto.html
      server = "https://acme.zerossl.com/v2/DV90";
      postRun = "systemctl restart coturn.service";
      group = "turnserver";
    };

    nixpkgs.overlays = [
      (self: super: {
        lego = super.lego.overrideAttrs (old: {
          # rebased from https://github.com/go-acme/lego/pull/1501
          patches = [ ./zerossl-account.patch ];
        });
      })
    ];

    sops.secrets."coturn/static_auth_secret" = { owner = "turnserver"; };
  }
