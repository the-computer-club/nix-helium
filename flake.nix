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
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Sketti config, for user packages
    terra.url = "github:skettisouls/nixos/ad97f1a34696466582d0cc79ab64ee8a39b89294";
  };

  outputs = inputs @ { self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; }
      (args@{ config, lib, ... }:
        let
          inherit (nixpkgs.lib) nixosSystem;
          rootConfig = config;
          this = (import ./lib.nix args);
          src = map (file: ./src/${file})
            (this.walkNixFiles ./src);
        in
        {
          imports = with inputs; [
            git-hooks-nix.flakeModule
            # lynx.flakeModules.flake-guard
            # asluni.flakeModules.asluni
            ./check-users.nix
          ];

          config = {
            # wireguard.enable = true;
            systems = [ "x86_64-linux" ];
            flake = {
              _debug = config;
              ##################
              # intended for
              # note: `nix repl`
              lib = lib.fix (
                lib.extends
                  (f: p: this)
                  (f: lib)
              );
              ##################

              modules.nixos = with inputs; [
                disko.nixosModules.disko
                lynx.nixosModules.flake-guard-host
                asluni.nixosModules.asluni
                sops.nixosModules.sops
                comin.nixosModules.comin

                /*
                  symlink source code into /etc
                  for easy access
                */
                { environment.etc.nixos.source = self; }
                { environment.etc.nixpkgs.source = nixpkgs; }
              ] ++ src;

              nixosConfigurations.helium = this.buildBox {
                specialArgs = { inherit self inputs; };
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

              packages.health-check =
                let
                  cfg = rootConfig.wireguard.build.networks.asluni;
                in
                pkgs.callPackage ./health-check.nix {
                  attestation = {
                    nmap = [{
                      host = "172.16.2.22";
                      port = 9999;
                      expected = "Golang x|crypto|ssh server";
                    }];

                    curl = [
                      {
                        host = "172.16.2.22";
                        resource = "/";
                        protocol = "http";
                        args = [
                          "-H"
                          "'Host: helium.luni'"
                        ];
                        expected = "Element web-chat";
                        status = 200;
                      }
                      {
                        host = "172.16.2.22";
                        resource = "/_matrix/client/helion.luni/register";
                        protocol = "http";
                        args = [
                          "-H"
                          "'Host: helium.luni'"
                        ];
                        status = "2[0-9][2]|3[0-9][2]";
                        expected = "";
                      }
                      # { check public view
                      #   host = "";
                      #   resource = "/_matrix/client/helion.luni/register";
                      #   protocol = "http";
                      #   args = [
                      #     "-H" "'Host: helion.luni'"
                      #   ];
                      #   status = 403;
                      # }
                    ];
                  };
                };

              devShells.default = pkgs.mkShell {
                shellHook = lib.concatStringsSep "\n" [
                  config.pre-commit.installationScript
                  ''
                    sops-recrypt() {
                      sops decrypt $1 | sops encrypt --filename-override ''${2:-$1} /dev/stdin
                    }
                  ''
                ];
                packages = with pkgs; [
                  sops
                  git-extras
                  git-bug
                  git
                  pre-commit
                  config.packages.health-check
                ];
              };

              checks.helium = pkgs.testers.runNixOSTest {
                name = "helium";

                /* allow unfree */
                node.pkgsReadOnly = false;
                node.specialArgs = {
                  inherit self inputs this;
                };

                nodes.tester = {
                  environment.systemPackages = [
                    # (config.packages.health-check.overrideAttrs
                    # (p: {
                    #   attestation = {
                    #     nmap = map (x: x // (lib.optionalAttrs (x.rewriteHostForTest) { host = "machine"; }))
                    #       p.attestation.nmap;
                    #     curl = map (x: x // (lib.optionalAttrs (x.rewriteHostForTest) { host = "machine"; }))
                    #       p.attestation.curl;
                    #   };
                    # }))
                  ];
                };

                nodes.machine.imports = rootConfig.flake.modules.nixos;

                testScript =
                  ''
                    # tester.start()
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

                    machine.wait_for_unit("sshd.service")
                    # tester.succeed("health-check")
                  '';
              };
            };
          };
        });
}
