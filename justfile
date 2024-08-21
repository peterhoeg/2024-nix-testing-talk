test:
  nix-build test.nix

interactive:
  $(nix-build -A driverInteractive test.nix)/bin/nixos-test-driver
