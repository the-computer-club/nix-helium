{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    lynx.url = "github:the-computer-club/lynx";
    asluni.url = "github:the-computer-club/automous-zones";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; }
  ({ ... }: let
    inherit (nixpkgs) lib;
    fileAttrs = lib.filterAttrs (_: t: t == "regular" ) (builtins.readDir ./src);
    fileList = with builtins; filter (lib.hasSuffix "nix") (attrNames fileAttrs);
    src = map (file: ./src/${file}) fileList;
  in {
    imports = with inputs; [
      lynx.flakeModules.builtins
      lynx.flakeModules.flake-guard
      asluni.flakeModules.asluni
    ];

    config = {
      systems = [ "x86_64-linux" ];
      flake = {
        nixosConfigurations.helium = lib.nixosSystem {
          specialArgs = { inherit inputs self; };
          modules = src ++ [
            inputs.disko.nixosModules.disko
          ];
        };
      };
    };
  });
}
