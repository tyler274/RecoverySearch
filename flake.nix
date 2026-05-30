{
  description = "RecoverySearch repo-level dev tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            git
            git-filter-repo
            act
            nodejs_22
          ];

          shellHook = ''
            echo "RecoverySearch root dev shell"
            echo "  git-filter-repo $(git-filter-repo --version 2>/dev/null || echo '(unavailable)')"
            echo "  act $(act --version 2>/dev/null || echo '(unavailable)')"
          '';
        };
      });
}
