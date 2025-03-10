{ config, lib, pkgs, ... }:
let
  cfg = config.flake.nixosConfigurations.helium.config;
in
{
  perSystem = { pkgs, ... }:
    {
      checks = lib.mapAttrs'
        (u: _:
          let
            env =
              if cfg.users.users ? "${u}" then
                cfg.users.users.${u}
              else
                throw "expected users.users.${u} bc of helion.remote.access.${u}";
          in
          lib.nameValuePair "user-env-${u}"
            (pkgs.buildEnv {
              name = "user-env-${u}";
              paths = env.packages ++ [ env.shell ];
            })
        )
        cfg.helion.remote.access;
    };
}
