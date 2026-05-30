{
  description = "RecoverySearch web app dev environment (Node + tooling)";

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
            nodejs_22
            # Supabase CLI: manages migrations and generates TypeScript types.
            supabase-cli
            # psql client for ad-hoc queries against the self-hosted db
            postgresql_17
          ];

          shellHook = ''
            export NEXT_TELEMETRY_DISABLED=1
            echo "RecoverySearch dev shell"
            echo "  node $(node --version), npm $(npm --version)"
            echo "  supabase $(supabase --version 2>/dev/null || echo '(unavailable)')"
          '';
        };
      });
}
