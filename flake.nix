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
        logic2-automation_pkg = pkgs.python3.pkgs.buildPythonPackage {
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
        
          # logic2-automation wants some protobuf code generated for it at build, this hook does just that
          preBuild = ''
            python ./grpc_build_hook.py
          '';

          # Optional data for nix tooling stuffs
          meta = with pkgs.lib; {
            description = "Python automation API for Saleae Logic 2";
            homepage = "https://github.com/saleae/logic2-automation";
            license = licenses.mit;
          };

          doCheck = false; # TODO: Add tests?
        };

        # Shrimple dev shell to allow for local debug
        devShell = pkgs.mkShell {
          buildInputs = with pkgs.python3.pkgs; [
            hatchling
            grpcio
            grpcio-tools
            protobuf
          ];

          packages = [
            logic2-automation_pkg
          ];

          shellHook = ''
            echo "Dev shell for logic2-automation ready"
          '';
        };

        # Overlay to extend nixpkgs in other flakes
        overlay = final: prev: {
          # The // is merging the prev version of python3Packages and exporting the merge as the final version
          python3Packages = prev.python3Packages // {
            logic2-automation = logic2-automation_pkg;
          };
        };

      in {
        packages.default = logic2-automation_pkg;
        devShells.default = devShell;
        overlays.default = overlay;
      }
    );
}
