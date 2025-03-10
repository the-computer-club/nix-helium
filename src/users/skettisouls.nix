{ inputs, config, pkgs, lib, ... }:
let
  system = "x86_64-linux";
  inherit (inputs.terra)
    packages
    wrappedPackages
    ;

  nvim-pkg = inputs.terra.inputs.neovim.packages.${system}.default;
  wpkgs = wrappedPackages.${system}.skettisouls;
  spkgs = packages.${system} // { neovim = nvim-pkg; };
in
{
  config = lib.mkIf config.helion.remote.access.skettisouls {
    users.users.skettisouls = {
      shell = wpkgs.nushell;
      extraGroups = [ "networkmanager" "wheel" ];
      packages = [
        wpkgs.lazygit
        wpkgs.nushell
        spkgs.rebuild
        # spkgs.neovim ! broken
        pkgs.btop
        pkgs.neofetch
      ];
    };
  };
}
