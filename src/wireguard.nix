{ config, ... }:
{
  sops = {
    defaultSopsFile = "${../secrets.${config.sops.defaultSopsFormat}}";
    defaultSopsFormat = "json";
    age.sshKeyPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];
    secrets.asluni = { };
  };

  wireguard.enable = true;
  wireguard.networks.asluni = {
    secretsLookup = "asluni";
    autoConfig = {
      openFirewall = true;
      "networking.wireguard" = {
        interface.enable = true;
        peers.mesh.enable = true;
      };
    };
  };
}
