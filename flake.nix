{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # Everything your flake provides
  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        # This combined with the flake-utils package abstracts what architecture you are building for
        pkgs = import nixpkgs { inherit system; };

        # Defines a package output built by this flake
        logic2-automation = pkgs.stdenv.mkDerivation {
          pname = "logic2-automation"; # So it knows what to build
          version = "1.0.7"; # Meta data stuffs

          src = pkgs.fetchFromGitHub {
            owner = "saleae";
            repo = "logic2-automation";
            rev = "6426540";
            sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };

          buildInputs = with pkgs.python3.pkgs; [
            hatchling
            grpcio-tools
          ];

          propagatedBuildInputs = with pkgs.python3.pkgs; [
            grpcio
            protobuf
          ];

          preBuild = ''
            # Generate grpc python files
            python -m grpc_tools.protoc -I. --python_out=./ --grpc_python_out=./ ./saleae/grpc/saleae.proto
          '';

          # All the steps needed to build the package
          buildPhase = ''
            mkdir -p dist
            pyinstaller --onefile main.py
          '';

          # Runs after everything is built
          installPhase = ''
            mkdir -p $out
            cp dist/main $out/pycd
          '';
        };

      # This is the part that define what and how things are exported
      in {
        packages.default = logic2-automation;
      }
    );
}
