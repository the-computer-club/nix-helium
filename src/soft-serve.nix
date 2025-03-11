{ lib
, pkgs
, config
, this
, ...
}:
let
  inherit (lib)
    attrValues
    flatten
    optionals
    mapAttrs
    mapAttrsToList
    ;

  maybeKey = this.maybeKey config.helion;
  cfg = config.helion.soft-serve;
in
{
  options.helion.soft-serve = {
    enable = lib.mkEnableOption "";
    admins = lib.mkOption {
      type = with lib.types; listOf str;
      default =
        flatten
          (mapAttrsToList (user: enabled:
            optionals enabled
              ((maybeKey "ssh-rsa" user) ++ (maybeKey "ssh-ed25519")))
          )
          config.helion.remote.access;
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
    systemd.services.soft-serve.restartTriggers = [
      ((pkgs.formats.yaml { }).generate "config.yaml" config.services.soft-serve.settings)
    ];

    services.soft-serve = {
      enable = true;
      settings = {
        name = "computer club repos";
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
