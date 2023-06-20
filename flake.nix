{
  description = "virtual environments";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    flake-utils,
    nixpkgs,
  }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages.default = let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
        pkgs.stdenv.mkDerivation {
          pname = "bc7enc";
          version = "1.0.0";

          src = ./.;

          nativeBuildInputs = with pkgs; [cmake llvmPackages_16.clang ninja];
	  buildInputs = with pkgs; [ llvmPackages_16.openmp ];
        };
    });
}
