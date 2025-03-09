{ config, lib, ... }:
with lib;
let
  keyOption = args: mkOption ({
    type = with types; attrsOf str;
    default = { };
  } // args);

  maybeKey = k: user:
    lib.optional
      (config.keys ? "${k}"
        && config.keys.${k} ? "${user}"
        && config.keys.${k}.${user} != null
        && config.keys.${k}.${user} != ""
      )
      config.keys.${k}.${user};
in
{
  options.keys = mkOption {
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

  options.remote.access = mkOption {
    type = types.attrsOf types.bool;
    default = { };
  };

  options.remote.store-keys = mkOption {
    type = types.attrsOf types.bool;
    default = { };
  };

  config.users.users = mapAttrs
    (name: bool: {
      openssh.authorizedKeys.keys =
        lib.optionals bool
          (maybeKey "ssh-ed25519" name)
        ++ (maybeKey "ssh-rsa" name);
    })
    config.remote.access;

  config.nix.settings.trusted-public-keys =
    lib.pipe config.remote.store-keys [
      (mapAttrsToList (name: bool: config.keys.store.${name} or null))
      (filter (x: x != null))
    ];
}
