{ self, inputs, config, lib, ... }:
let
  inherit (inputs.nixpkgs.lib) nixosSystem;
  inherit (lib)
    mkOption
    types
    hasSuffix
    filterAttrs
    pipe
    fix
    extends
    ;

  inherit (builtins)
    readDir
    attrNames
    filter;

  /* this flakes library */
  this = rec {
    buildBox = args: nixosSystem (args // {
      specialArgs =
        if args ? specialArgs then
          args.specialArgs // { inherit this; }
        else { inherit this; };
    });

    keyOption = args: mkOption ({
      type = with types; attrsOf str;
      default = { };
    } // args);

    maybeKey = cfg: k: user:
      lib.optional
        (cfg.keys ? "${k}"
          && cfg.keys.${k} ? "${user}"
          && cfg.keys.${k}.${user} != null
          && cfg.keys.${k}.${user} != ""
        )
        cfg.keys.${k}.${user};

    walkNixFiles =
      filepath:
      (filter (hasSuffix "nix"))
        (attrNames
          ((filterAttrs (_: t: t == "regular"))
            (readDir filepath)));
  };
in
this
