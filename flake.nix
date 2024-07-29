{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = [
      "https://slippi-nix.cachix.org"
    ];

    extra-trusted-public-keys = [
      "slippi-nix.cachix.org-1:2qnPHiOxTRpzgLEtx6K4kXq/ySDg7zHEJ58J6xNDvBo="
    ];
  };

  outputs = {
    nixpkgs,
    git-hooks,
    self,
    ...
  }: let
    forSystems = nixpkgs.lib.genAttrs [
      # "aarch64-linux"
      # "aarch64-darwin"
      # "x86_64-darwin"
      "x86_64-linux"
    ];
    pkgsFor = system: (import nixpkgs {inherit system;});
    genPkgs = func: (forSystems (system: func (pkgsFor system)));
  in {
    overlays = {
      default = self.outputs.overlays.slippi;

      slippi = final: prev: {
        inherit (self.outputs.packages.${final.system}.slippi) slippi-netplay slippi-playback slippi-launcher;
      };
    };

    packages = genPkgs (pkgs: {
      default = self.outputs.packages.${pkgs.system}.slippi-launcher;
      slippi-netplay = pkgs.callPackage packages/netplay.nix {};
      slippi-playback = pkgs.callPackage packages/playback.nix {};
      slippi-launcher = pkgs.callPackage packages/launcher.nix {};
    });

    checks =
      genPkgs (pkgs: {
        git-hooks = git-hooks.lib.${pkgs.system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
          };
        };
      })
      // self.outputs.packages;

    nixosModules = {
      default = {
        imports = with self.outputs.nixosModules; [
          gamecube-controller-adapter
        ];
      };

      gamecube-controller-adapter = import ./modules/nixos/gamecube-controller-adapter.nix;
    };

    homeManagerModules = {
      default = {
        imports = with self.outputs.homeManagerModules; [
          slippi-launcher
        ];
      };

      slippi-launcher = import ./modules/home-manager/slippi/launcher.nix (system: self.outputs.packages.${system}.slippi);
    };
  };
}
