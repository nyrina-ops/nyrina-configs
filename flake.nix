{
  inputs = {
    nixpkgs.url = "github:ashkitten/nixpkgs/nyrina";

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, impermanence, sops-nix, ... }: {
    nixosConfigurations = {
      xenia = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";

        modules = [
          impermanence.nixosModules.impermanence
          sops-nix.nixosModules.sops
          ./xenia
        ];
      };
    };

    devShells."x86_64-linux".default = import ./shell.nix {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
    };
  };
}
