{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.helion.remote.access.lunarix {
    programs.fish.enable = true;
    users.users.lunarix = {
      shell = pkgs.fish;
      isNormalUser = true;
      initialPassword = "nixos";
      extraGroups = [ "networkmanager" "wheel" ];
    };
  };
}
