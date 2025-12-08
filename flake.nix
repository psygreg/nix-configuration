{
  description = "Additional repositories and cache";

  inputs = {
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    preload-ng.url = "github:miguel-b-p/preload-ng";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nix-flatpak, lanzaboote, preload-ng } @ inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
      { nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem { # Replace "nixos" with your system's hostname
          specialArgs = { 
            inherit inputs unstable;
          };
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            nix-flatpak.nixosModules.nix-flatpak
            lanzaboote.nixosModules.lanzaboote
	          preload-ng.nixosModules.default 
	          { services.preload-ng.enable = true; }
          ];
        };
      };
  };

  nixConfig = {
    extra-substituters = [
      "https://nixpkgs.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
    ];
  };
}
