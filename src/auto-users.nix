{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;

  cfg = config.helion;
in
{
  options.helion.users = mkOption {
    type = with types; attrsOf (submodule {
      options = {
        extraGroups = mkOption {
          type = listOf str;
          default = [];
        };

        # Required to access the machine
        sshKeys = mkOption {
          type = listOf str;
        };
      };
    });
  };

  config.users.users = lib.mapAttrs (user: ucfg: {
    isNormalUser = true;
    extraGroups = lib.mkDefault [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = ucfg.sshKeys;
  }) cfg.users;
}
