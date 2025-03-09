{ inputs, pkgs, ... }:
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
  users.users.skettisouls = {
    shell = wpkgs.nushell;
    packages = [
      wpkgs.lazygit
      wpkgs.nushell
      spkgs.rebuild
      spkgs.neovim
      pkgs.btop
      pkgs.neofetch
    ];
  };
}
