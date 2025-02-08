{ ... }:

{
  helion = rec {
    keys.flagship = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILcon6Pn5nLNXEuLH22ooNR97ve290d2tMNjpM8cTm2r";

    users.lunarix = {
      sshKeys = with keys; [ flagship ];
      # shell = pkgs.zsh?;
      # packages = [];
    };
  };
}
