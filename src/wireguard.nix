{
  wireguard.enable = true;
  wireguard.networks.asluni = {
    # TODO: Secrets (luni pls)
    privateKeyFile = "/var/lib/wireguard/privatekey";

    autoConfig = {
      openFirewall = true;

      "networking.wireguard" = {
        interface.enable = true;
        peers.mesh.enable = true;
      };

      # Probably uneeded? unsure atm
      # "networking.hosts" = {
      #   enable = true;
      #   FQDNs.enable = true;
      # };
    };

    peers.by-name.asluni = {
      publicKey = "XogPdWcXlA+3exaYD3sJSOKp9qXlIltvyAmDvF2n0D8=";
      ipv4 = [ "172.16.2.21" ];
      selfEndpoint = "107.173.122.172:63723";
    };
  };
}
