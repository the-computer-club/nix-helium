{ inputs, config, lib, ... }:
{
  options.flake.rev = lib.mkOption {
    default = inputs.self.dirtyRev or inputs.self.rev;
    type = with lib.types; nullOr string;
  };
}
