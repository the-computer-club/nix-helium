{ inputs, config, pkgs, lib, ... }:
{
  keys.ssh-ed25519 = {
    argon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILU3q+/0jJLkAtvCk3hJ+QAXCvza7SZ9a0V6FZq6IJne";
    sky = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBA9i9HoP7X8Ufzz8rAaP7Nl3UOMZxQHMrsnA5aEQfpTyIQ1qW68jJ4jGK5V6Wv27MMc3czDU1qfFWIbGEWurUHQ=";
    lunarix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILcon6Pn5nLNXEuLH22ooNR97ve290d2tMNjpM8cTm2r";
  };

  remote.access = {
    argon = true;
    lunarix = true;
  };

  # MBR
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  systemd.services.NetworkManager-wait-online.enable = false;
  networking = {
    hostName = "helium";
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [ 22 ];
  };

  services = {
    openssh = {
      enable = true;
      openFirewall = false;
      passwordAuthentication = false;
    };
  };

  nixpkgs.config.allowUnfree = true;
  nix = {
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    package = pkgs.nix;
    registry = lib.mapAttrs (_: flake: { inherit flake; }) inputs;
    settings.experimental-features = [ "nix-command" "flakes" ];

    extraOptions = ''
      trusted-users = root skettisouls lunarix
    '';
  };

  time.timeZone = "America/Chicago";
  system.stateVersion = "24.11";
}
