{ lib
, pkgs
, config
, ...
}:
let
  inherit (lib)
    attrValues
    flatten
    mapAttrs
    ;

  cfg = config.helion.soft-serve;
in
{
  options.helion.soft-serve = {
    enable = lib.mkEnableOption "";
    admins = lib.mkOption {
      type = with lib.types; listOf str;
      default = flatten (attrValues (mapAttrs (_: ucfg: ucfg.sshKeys) config.helion.users));
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 9999;
    };
    domain = lib.mkOption {
      default = "git.helium.luni";
      type = lib.types.str;
    };
  };
  config = lib.mkIf cfg.enable {
    # This fix was recently added to upstream but is not in repo yet
    systemd.services.soft-serve.restartTriggers = [
      ((pkgs.formats.yaml { }).generate "config.yaml" config.services.soft-serve.settings)
    ];

    services.soft-serve = {
      enable = true;
      settings = {
        name = "luni repos";
        log_format = "text";
        ssh = {
          listen_addr = ":${builtins.toString cfg.port}";
          public_url = "ssh://${cfg.domain}:${builtins.toString cfg.port}";
        };
        stats.listen_addr = ":23235";
        lfs.enabled = true;
        initial_admin_keys = cfg.admins;
      };
    };

  };
}
