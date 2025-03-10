{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.local.matrix;
in
{
  options.local.matrix = {
    enable = lib.mkEnableOption "enables matrix";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
    };
    secrets = {
      coturn = lib.mkOption { type = lib.types.path; };
      matrixRegistration = lib.mkOption { type = lib.types.path; };
    };
  };
  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      initialScript = pkgs.writeText "init-sql-script" ''
        CREATE USER "matrix-synapse";
        CREATE DATABASE "matrix-synapse"
          ENCODING 'UTF8'
          LC_COLLATE='C'
          LC_CTYPE='C'
          template=template0
          OWNER "matrix-synapse";
      '';
    };
    services.matrix-synapse = {
      enable = true;
      extraConfigFiles = [
        cfg.secrets.coturn
        cfg.secrets.matrixRegistration
      ];
      settings = {
        enable_registration = true;
        database_type = "psycopg2";
        database_args = {
          database = "matrix-synapse";
        };
        server_name = cfg.domain;
        public_baseurl = "https://${cfg.domain}";
        turn_uris = [
          "turn:${config.local.coturn.domain}:3487?transport=udp"
          "turn:${config.local.coturn.domain}:3487?transport=tcp"
          "turns:${config.local.coturn.domain}:5349?transport=udp"
          "turns:${config.local.coturn.domain}:5349?transport=tcp"
        ];
        listeners = [
          {
            port = 8008; # TODO: setup reverse proxy with https
            bind_addresses = [
              "::1"
              "127.0.0.1"
            ];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [
              {
                names = [
                  "client"
                  # "federation"
                ];
                compress = true;
              }
            ];
          }
        ];
      };
    };
  };
}
