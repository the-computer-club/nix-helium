{ config, lib, ... }:
let
  inherit (lib) mkDefault;
in
{
  sops = {
    defaultSopsFile = "${../secrets/default.${config.sops.defaultSopsFormat}}";
    defaultSopsFormat = "json";
    secrets.asluni = { };
  };

  wireguard.defaults.autoConfig = {
    openFirewall = mkDefault true;

    "networking.wireguard" = {
      interface.enable = mkDefault true;
      peers.mesh.enable = mkDefault true;
    };

    "networking.hosts" = {
      FQDNs.enable = mkDefault true;
      names.enable = mkDefault true;
    };
  };

}
