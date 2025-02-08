{ lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  options.helion.keys = mkOption {
    type = with types; attrsOf str;
    default = {};
  };
}
