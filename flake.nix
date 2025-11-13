{
  description = "Chaotic-Nyx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"; # IMPORTANT
  };

  outputs = { self, nixpkgs, chaotic } @ inputs: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem { # Replace "nixos" with your system's hostname
        specialArgs = { inherit inputs; };
	system = "x86_64-linux";
        modules = [
          ./configuration.nix
          chaotic.nixosModules.default # IMPORTANT
        ];
      };
    };
  };
}
