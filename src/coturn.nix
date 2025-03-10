{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.local.coturn;
in
{
  options.local.coturn = {
    enable = lib.mkEnableOption "enables coturn";
    certPath = lib.mkOption {
      type = lib.types.string;
    };
    keyPath = lib.mkOption {
      type = lib.types.string;
    };
    domain = lib.mkOption {
      type = lib.types.string;
    };
    static-auth-secret-file = lib.mkOption {
      type = lib.types.path;
    };
  };
  config = lib.mkIf cfg.enable {
    services.coturn = {
      enable = true;
      no-cli = true;
      no-tcp-relay = true;
      min-port = 49000;
      max-port = 50000;
      use-auth-secret = true;
      inherit (cfg) static-auth-secret-file;
      realm = cfg.domain;
      cert = cfg.certPath;
      pkey = cfg.keyPath;
      extraConfig = ''
        # for debugging
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
    # open the firewall
    networking.firewall = {
      interfaces.enp2s0 =
        let
          range =
            with config.services.coturn;
            lib.singleton {
              from = min-port;
              to = max-port;
            };
        in
        {
          allowedUDPPortRanges = range;
          allowedUDPPorts = [
            3478
            5349
          ];
          allowedTCPPortRanges = [ ];
          allowedTCPPorts = [
            3478
            5349
          ];
        };
    };
  };
}
