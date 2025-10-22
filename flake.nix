{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [ inputs.treefmt-nix.flakeModule ];

      perSystem =
        {
          pkgs,
          system,
          ...
        }:
        let
          mcpConfig = inputs.mcp-servers-nix.lib.mkConfig pkgs {
            programs = {
              serena.enable = true;
              nixos.enable = true;
            };
          };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.rust-overlay.overlays.default
            ];
          };

          packages = {
            mcp-config = mcpConfig;
          };

          devShells.default = with pkgs; mkShell {
              buildInputs = [
                openssl
                pkg-config
                rust-bin.stable.latest.default
              ];

              shellHook = ''
                cat ${mcpConfig} > .mcp.json
                echo "Generated .mcp.json"
              '';
            };

          treefmt = {
            programs = {
              nixfmt.enable = true;
              rustfmt.enable = true;
            };
          };
        };
    };
}
