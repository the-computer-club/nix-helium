{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.helion.remote.access.sky {
    programs.fish.enable = true;
    users.users.sky = {
      shell = pkgs.fish;
      isNormalUser = true;
      initialPassword = "nixos";
      extraGroups = [ "networkmanager" "wheel" ];
    };
  };
}
