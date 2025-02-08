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
    src = with builtins; map (file: ./src/${file}) (attrNames (readDir ./src));
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
