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

        # Its not in nixpkgs so we have to fetch from source
        logic2-automation = pkgs.python3.pkgs.buildPythonPackage {
          pname = "logic2-automation"; # So it knows what to build
          version = "1.0.7"; # Meta data stuffs
          pyproject = true; # So it knows how to build
          sourceRoot = "source/python"; # So it knows where it needs to build from

          src = pkgs.fetchFromGitHub {
            owner = "saleae";
            repo = "logic2-automation";
            rev = "6426540";
            sha256 = "sha256-G0fYkjJITe5XY39U3aoaEofgmicdBjghI4I0rCN7m8k=";
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
            python ./grpc_build_hook.py
          '';
        };

      # This is the part that define what and how things are exported
      in {
        packages.default = logic2-automation;
      }
    );
}
