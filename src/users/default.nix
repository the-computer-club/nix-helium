{ lib, ... }:
let
  fileAttrs = lib.filterAttrs (n: t: t == "regular" && n != "default.nix") (builtins.readDir ./.);
  fileList = with builtins; filter (lib.hasSuffix "nix") (attrNames fileAttrs);
in
{
  imports = map (file: ./${file}) fileList;
}
