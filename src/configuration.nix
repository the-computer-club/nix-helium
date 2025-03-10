{ inputs, pkgs, lib, ... }:

{
  helion = {
    keys.ssh-ed25519 = {
      skettisouls = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILU3q+/0jJLkAtvCk3hJ+QAXCvza7SZ9a0V6FZq6IJne";
      lunarix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILcon6Pn5nLNXEuLH22ooNR97ve290d2tMNjpM8cTm2r";
    };

    remote.access = {
      skettisouls = true;
      lunarix = true;
    };
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
      settings = {
        PasswordAuthentication = false;
      };
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

  virtualisation.vmVariant.virtualisation.sharedDirectories = {
    secrets = {
      source = "/etc/ssh";
      target = "/etc/ssh";
      securityModel = "passthrough";
    };
  };
}
