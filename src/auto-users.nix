{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;

  cfg = config.helion;
in
{
  imports = [ ./users ];
  options.helion.users = mkOption {
    type = with types; attrsOf (submodule {
      options = {
        packages = mkOption {
          type = listOf package;
          default = [];
        };

        extraGroups = mkOption {
          type = listOf str;
          default = [];
        };

        # Required to access the machine
        sshKeys = mkOption {
          type = listOf str;
        };

        shell = mkOption {
          type = nullOr package;
          default = null;
        };
      };
    });
  };

  config.users.users = lib.mapAttrs (user: ucfg: {
    isNormalUser = true;
    extraGroups = lib.mkDefault [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = ucfg.sshKeys;
    packages = ucfg.packages;
    shell = lib.mkIf (ucfg.shell != null) ucfg.shell;
  }) cfg.users;
}
