{ config, lib, ... }:
with lib;
let
  keyOption = args: mkOption ({
    type = with types; attrsOf str;
    default = { };
  } // args);

  maybeKey = k: user:
    lib.optional
      (cfg.keys ? "${k}"
        && cfg.keys.${k} ? "${user}"
        && cfg.keys.${k}.${user} != null
        && cfg.keys.${k}.${user} != ""
      )
      cfg.keys.${k}.${user};

  cfg = config.helion;
in
{
  options.helion = {
    keys = mkOption {
      default = { };
      type = types.submoduleWith {
        modules = [
          { freeformType = types.attrsOf (types.attrsOf types.str); }
          {
            ssh-ed25519 = keyOption { };
            ssh-rsa = keyOption { };
            store = keyOption { };
          }
        ];
      };
    };

    remote = {
      access = mkOption {
        type = types.attrsOf types.bool;
        default = { };
      };

      store-keys = mkOption {
        type = types.attrsOf types.bool;
        default = { };
      };
    };
  };

  config = {
    users.users = mapAttrs
      (name: bool: {
        isNormalUser = true;
        openssh.authorizedKeys.keys =
          lib.optionals bool
            (maybeKey "ssh-ed25519" name)
          ++ (maybeKey "ssh-rsa" name);
      })
      cfg.remote.access;

    nix.settings.trusted-public-keys =
      lib.pipe cfg.remote.store-keys [
        (mapAttrsToList (name: bool: cfg.keys.store.${name} or null))
        (filter (x: x != null))
      ];
  };
}
