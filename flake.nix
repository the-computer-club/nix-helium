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
          rootConfig = config;
          fileAttrs = lib.filterAttrs (_: t: t == "regular") (builtins.readDir ./src);
          fileList = with builtins; filter (lib.hasSuffix "nix") (attrNames fileAttrs);
          src = map (file: ./src/${file}) fileList;
        in
        {
          imports = with inputs; [
            git-hooks-nix.flakeModule
            lynx.flakeModules.flake-guard
            ./check-users.nix
          ];

          config = {
            systems = [ "x86_64-linux" ];
            flake = {
              modules.nixos = with inputs; [
                disko.nixosModules.disko
                lynx.nixosModules.flake-guard-host
                asluni.nixosModules.asluni
                sops.nixosModules.sops
                # { environment.etc.nixos.source = self; }
                { environment.etc.nixpkgs.source = nixpkgs; }
              ] ++ src;

              nixosConfigurations.helium = lib.nixosSystem {
                specialArgs = { inherit inputs self; };
                modules = config.flake.modules.nixos;
              };
            };
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
                  ''
                    sops-recrypt() {
                      sops decrypt $1 | sops encrypt --filename-override $1 /dev/stdin
                    }
                  ''
                ];
                packages = with pkgs; [
                  sops
                  git-extras
                  git-bug
                  git
                  pre-commit
                ];
              };

              checks.helium = pkgs.testers.runNixOSTest {
                name = "helium";
                node.pkgsReadOnly = false;
                node.specialArgs = { inherit inputs self; };
                nodes.machine.imports = rootConfig.flake.modules.nixos;
                testScript =
                  ''
                    machine.start()
                    machine.wait_for_unit("default.target")
                    ${
                      let
                        cfg = rootConfig.flake.nixosConfigurations.helium.config;
                      in
                      lib.pipe cfg.helion.remote.access [
                        (lib.mapAttrsToList(u: enabled: ''machine.${
                          if enabled then "succeed"
                          else "fail"
                        }("id -nG ${u} | grep 'wheel'")''))
                        (lib.concatStringsSep "\n")
                      ]
                    }
                    machine.succeed("id -nG lunarix | grep -qw 'wheel'")
                  '';
              };
            };
          };
        });
}
