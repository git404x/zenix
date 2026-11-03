{
  description = "zenix: personal and community nix package repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      nixosModules = {
        default = import ./pkgs/brave/module.nix { isHomeManager = false; };
        brave = import ./pkgs/brave/module.nix { isHomeManager = false; };
      };
      homeManagerModules = {
        default = import ./pkgs/brave/module.nix { isHomeManager = true; };
        brave = import ./pkgs/brave/module.nix { isHomeManager = true; };
      };
    in
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        bravePackages = pkgs.callPackage ./pkgs/brave/default.nix { };
      in
      {
        packages = (builtins.removeAttrs bravePackages [ "override" "overrideDerivation" ]) // {
          default = bravePackages.brave-origin;
        };
      }
    )
    // {
      inherit nixosModules homeManagerModules;

      overlays.default = final: prev: {
        bravePackages = final.callPackage ./pkgs/brave/default.nix { };
        brave = final.bravePackages.brave;
        brave-beta = final.bravePackages.brave-beta;
        brave-origin = final.bravePackages.brave-origin;
        brave-origin-beta = final.bravePackages.brave-origin-beta;
      };
    };
}
