{
  inputs = {
    nixpkgs.url = "github:ashkitten/nixpkgs/nyrina";

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, colmena, impermanence, sops-nix, ... }: {
    nixosConfigurations = {
      xenia = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";

        modules = [
          impermanence.nixosModules.impermanence
          sops-nix.nixosModules.sops
          ./xenia
          { deployment.buildOnTarget = true; }
        ];

        extraModules = [
          colmena.nixosModules.deploymentOptions
        ];
      };
    };

    colmena = {
      meta.nixpkgs = import nixpkgs {};
    } // builtins.mapAttrs (name: value: {
      nixpkgs.system = value.config.nixpkgs.system;
      imports = value._module.args.modules;
    }) (self.nixosConfigurations);

    devShells."x86_64-linux".default = import ./shell.nix {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
    };
  };
}
