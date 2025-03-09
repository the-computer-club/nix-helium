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
      ({ ... }:
        let
          inherit (nixpkgs) lib;
          fileAttrs = lib.filterAttrs (_: t: t == "regular") (builtins.readDir ./src);
          fileList = with builtins; filter (lib.hasSuffix "nix") (attrNames fileAttrs);
          src = map (file: ./src/${file}) fileList;
        in
        {
          imports = with inputs; [
            lynx.flakeModules.builtins
            lynx.flakeModules.flake-guard
            asluni.flakeModules.asluni
          ];

          config = {
            systems = [ "x86_64-linux" ];
            flake = {
              nixosConfigurations.helium = lib.nixosSystem
                {
                  specialArgs = { inherit inputs self; };
                  modules = src ++ [
                    inputs.disko.nixosModules.disko
                  ];
                  config = {
                    systems = [ "x86_64-linux" ];

                    perSystem = { config, pkgs, ... }: {
                      pre-commit.check.enable = true;

                      pre-commit.settings.hooks = {
                        trim-trailing-whitespace.enable = true;
                        nixpkgs-fmt.enable = true;
                        flake-checker.enable = true;
                      };

                      devShells.default = pkgs.mkShell {
                        shellHook = lib.concatStringsSep "\n" [
                          config.pre-commit.installationScript
                        ];
                        packages = with pkgs; [
                          pre-commit
                        ];
                      };
                    };

                    flake = {
                      nixosConfigurations.helium = lib.nixosSystem {
                        specialArgs = { inherit inputs self; };
                        modules = src ++ [
                          inputs.disko.nixosModules.disko
                          inputs.lynx.nixosModules.flake-guard-host
                        ];
                      };
                    };
                  };
                });
            }
