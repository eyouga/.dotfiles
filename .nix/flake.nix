{
  description = "nix-darwin flake boilerplate";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kwin-effects-forceblur = {
      url = "github:taj-ny/kwin-effects-forceblur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fjordlauncher = {
      url = "github:unmojang/FjordLauncher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      darwin,
      nixpkgs,
      ...
    }:
    {
      darwinConfigurations = {
        # m1-macbook
        "eminem" = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/eminem.nix ];
        };
        # intel-macbook (used for CI to test updates)
        "intel-macbook" = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          specialArgs = inputs;
          modules = [ ./hosts/intel-macbook.nix ];
        };
      };
      nixosConfigurations = {
        biggie = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/biggie/configuration.nix ];
        };
        iso = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            (
              { pkgs, modulesPath, ... }:
              {
                imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
              }
            )
            # ./configuration.nix
          ];
        };
      };
    };
}
