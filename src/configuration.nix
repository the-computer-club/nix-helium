{ inputs, config, lib, pkgs, ... }:
let
  inherit (config.helion) keys;
in
{
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


  programs.git = {
    enable = true;
    config = {
      safe = {
        directory = "/etc/nixos";
      };
    };
  };

  services = {
    openssh = {
      enable = true;
      openFirewall = false;
      settings =  {
        PasswordAuthentication = false;
      };
    };
  };

  # See ./keys.nix
  users.users.root.openssh.authorizedKeys.keys = with keys; [ argon flagship ];

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
