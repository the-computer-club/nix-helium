# helium



## Building test Environment
```sh
git clone git@github.com:the-computer-club/nix-helium.git
cd nix-helium

nix develop

nixos-rebuild build-vm --flake .#helium

# sudo is needed for accessing host's /etc/ssh
sudo /nix/store/<hash>-run-helium-vm
```

