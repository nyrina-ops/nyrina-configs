{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "67.207.67.2" "67.207.67.3" ];
    defaultGateway = "162.243.169.1";
    defaultGateway6 = "2604:a880:400:d0::1";
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="162.243.169.163"; prefixLength=24; }
          { address="10.10.0.5"; prefixLength=16; }
        ];
        ipv6.addresses = [
          { address="2604:a880:400:d0::1bd2:b001"; prefixLength=64; }
          { address="fe80::605a:79ff:fe96:2a83"; prefixLength=64; }
        ];
        ipv4.routes = [ { address = "162.243.169.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "2604:a880:400:d0::1"; prefixLength = 128; } ];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="62:5a:79:96:2a:83", NAME="eth0"
    ATTR{address}=="d2:77:84:74:76:3f", NAME="eth1"
  '';
}
