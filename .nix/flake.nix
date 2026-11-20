{
  description = "eyouga's machines: def-jam and biggie (NixOS), eminem (nix-darwin), install ISOs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      # Only its home-manager module needs this, and nothing here uses it.
      inputs.home-manager.follows = "";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kwin-effects-better-blur-dx = {
      url = "github:xarblu/kwin-effects-better-blur-dx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    millennium.url = "github:SteamClientHomebrew/Millennium/next?dir=packages/nix";
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
    magnuspladsen-tap = {
      url = "github:magnuspladsen/homebrew-tap";
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
        eminem = darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/eminem.nix ];
        };
      };
      nixosConfigurations = {
        biggie = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/biggie/configuration.nix ];
        };
        def-jam = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/def-jam/configuration.nix ];
        };
        iso-minimal = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/isos/minimal.nix ];
        };
        iso-graphical = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ./hosts/isos/graphical.nix ];
        };
      };
      # The tools CI runs, the same on the Mac: `nix develop ./.nix -c .nix/scripts/ci/lint.sh`.
      devShells = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              actionlint
              deadnix
              lua51Packages.luacheck
              nixfmt
              shellcheck
              shfmt
              statix
              stylua
              zsh
            ];
          };
        }
      );
      # nix build .#iso-minimal / .#iso-graphical
      packages.x86_64-linux = {
        iso-minimal = self.nixosConfigurations.iso-minimal.config.system.build.isoImage;
        iso-graphical = self.nixosConfigurations.iso-graphical.config.system.build.isoImage;
      };
    };
}
