{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";

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
    nixosConfigurations.meandrina = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        impermanence.nixosModules.impermanence
        sops-nix.nixosModules.sops
        ./configuration.nix
      ];

      extraModules = [
        colmena.nixosModules.deploymentOptions
      ];
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
