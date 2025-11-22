{
  description = "Chaotic-Nyx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"; # IMPORTANT
    affinity-nix.url = "github:mrshmllow/affinity-nix";
  };

  outputs = { self, nixpkgs, chaotic, affinity-nix } @ inputs: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem { # Replace "nixos" with your system's hostname
        specialArgs = { inherit inputs; };
	system = "x86_64-linux";
        modules = [
          ./configuration.nix
          chaotic.nixosModules.default # IMPORTANT
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