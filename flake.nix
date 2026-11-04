{
  description = "zenix: personal and community nix package repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      home-manager,
    }:
    let
      nixosModules = {
        default = import ./modules/nixos { inherit self; };
        brave = import ./pkgs/brave/module.nix { isHomeManager = false; };
        zen-browser = import ./pkgs/zen/module.nix { isHomeManager = false; };
      };

      homeManagerModules = {
        default = import ./modules/home-manager { inherit self; };
        brave = import ./pkgs/brave/module.nix { isHomeManager = true; };
        zen-browser = import ./pkgs/zen/module.nix {
          isHomeManager = true;
          inherit home-manager;
        };
      };
    in
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        bravePackages = pkgs.callPackage ./pkgs/brave/default.nix { };
        zenPackages = pkgs.callPackage ./pkgs/zen/default.nix { };
      in
      {
        packages = (builtins.removeAttrs bravePackages [ "override" "overrideDerivation" ]) // {
          default = bravePackages.brave-origin;
          zen-browser = zenPackages.default;
          zen-browser-beta = zenPackages.beta;
          zen-browser-twilight = zenPackages.twilight;
        };
      }
    )
    // {
      inherit nixosModules homeManagerModules;
      homeModules = homeManagerModules;

      overlays.default = final: prev: {
        bravePackages = final.callPackage ./pkgs/brave/default.nix { };
        brave = final.bravePackages.brave;
        brave-beta = final.bravePackages.brave-beta;
        brave-origin = final.bravePackages.brave-origin;
        brave-origin-beta = final.bravePackages.brave-origin-beta;

        zenPackages = final.callPackage ./pkgs/zen/default.nix { };
        zen-browser = final.zenPackages.default;
        zen-browser-beta = final.zenPackages.beta;
        zen-browser-twilight = final.zenPackages.twilight;
      };
    };
}
