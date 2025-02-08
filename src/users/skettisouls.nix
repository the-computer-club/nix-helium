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
  helion = rec {
    keys.argon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILU3q+/0jJLkAtvCk3hJ+QAXCvza7SZ9a0V6FZq6IJne";

    users.skettisouls = {
      sshKeys = with keys; [ argon ];
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
  };
}
