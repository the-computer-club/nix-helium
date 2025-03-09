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
      ({ config, ... }:
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
              modules.nixos = src ++ [
                inputs.disko.nixosModules.disko
              ];

              nixosConfigurations.helium = lib.nixosSystem {
                specialArgs = { inherit inputs self; };
                modules = config.modules.nixos;
              };
            };

            perSystem = { pkgs, ... }: {
              checks.helium = pkgs.testers.runNixOSTest {
                name = "helium";
                node.pkgsReadOnly = false;
                node.specialArgs = { inherit inputs self; };
                nodes.machine.imports = config.modules.nixos;
                testScript =
                  ''
                    machine.start()
                    machine.wait_for_unit("default.target")
                    machine.success("id -nG lunarix | grep -qw 'wheel'")
                    machine.success("id -nG skettisouls | grep -qw 'wheel'")
                  '';
              };
            };
          };
        });
}
