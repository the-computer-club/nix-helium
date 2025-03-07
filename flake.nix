{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    lynx.url = "github:the-computer-club/lynx/flake-guard-v2";
    asluni.url = "github:the-computer-club/automous-zones";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    sops.url = "github:Mic92/sops-nix";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Sketti config, for user packages
    terra.url = "github:skettisouls/nixos";
  };

  outputs = inputs @ { self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; }
      ({ config, ... }:
        let
          inherit (nixpkgs) lib;
          fileAttrs = lib.filterAttrs (_: t: t == "regular") (builtins.readDir ./src);
          fileList = with builtins; filter (lib.hasSuffix "nix") (attrNames fileAttrs);
          src = map (file: ./src/${file}) fileList;
        in
        {
          imports = with inputs; [
            git-hooks-nix.flakeModule
            lynx.flakeModules.flake-guard
          ];

          config = {
            systems = [ "x86_64-linux" ];

            perSystem = { config, pkgs, ... }: {
              pre-commit.check.enable = true;

              pre-commit.settings.hooks = {
                trim-trailing-whitespace.enable = true;
                nixpkgs-fmt.enable = true;
              };

              devShells.default = pkgs.mkShell {
                shellHook = lib.concatStringsSep "\n" [
                  config.pre-commit.installationScript
                  ''
                    sops-recrypt() {
                      sops decrypt $1 | sops encrypt --filename-override $1 /dev/null
                    }
                  ''
                ];
                packages = with pkgs; [
                  sops
                  direnv
                  git-extras
                  git-bug
                  git
                  pre-commit
                ];
              };
            };

            flake = {
              nixosConfigurations.helium = lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = with inputs; [
                  disko.nixosModules.disko
                  lynx.nixosModules.flake-guard-host
                  asluni.nixosModules.asluni
                  sops.nixosModules.sops
                  # { environment.etc.nixos.source = self; }
                  { environment.etc.nixpkgs.source = nixpkgs; }
                ] ++ src;
              };
            };
          };
        });
}
