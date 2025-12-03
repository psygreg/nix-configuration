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
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    affinity-nix.url = "github:mrshmllow/affinity-nix";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, chaotic, nix-flatpak, affinity-nix, lanzaboote } @ inputs:
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
            chaotic.nixosModules.default
            nix-flatpak.nixosModules.nix-flatpak
            lanzaboote.nixosModules.lanzaboote
            { environment.systemPackages = [affinity-nix.packages.x86_64-linux.v3]; }
          ];
        };
      };
  };

  nixConfig = {
    extra-substituters = [
      "https://nixpkgs.cachix.org"
      "https://chaotic-nyx.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    ];
  };
}
