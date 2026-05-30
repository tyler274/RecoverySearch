{
  description = "RecoverySearch repo-level dev tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # terraform is distributed under the BSL and is marked unfree in
        # nixpkgs, so allow it explicitly for this dev shell.
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            git
            git-filter-repo
            act
            nodejs_22
            # Terraform CLI for the infra/ multi-cloud deployment configs.
            terraform
          ];

          shellHook = ''
            echo "RecoverySearch root dev shell"
            echo "  git-filter-repo $(git-filter-repo --version 2>/dev/null || echo '(unavailable)')"
            echo "  act $(act --version 2>/dev/null || echo '(unavailable)')"
            echo "  terraform $(terraform version 2>/dev/null | head -n1 || echo '(unavailable)')"
          '';
        };
      });
}
