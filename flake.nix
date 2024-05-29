{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    nixpkgs,
    self,
    ...
  }: let
    forSystems = nixpkgs.lib.genAttrs ["aarch64-linux" "aarch64-darwin" "x86_64-darwin" "x86_64-linux"];
    pkgsFor = system: ((import nixpkgs {inherit system;}).extend self.outputs.overlays.base);
  in {
    overlays = {
      default = self.outputs.overlays.slippi;

      slippi = final: prev: {
        slippi = self.outputs.packages.${final.system}.slippi;
      };

      base = final: prev: {
        callAppImage = final.callPackage lib/appimage.nix {};
      };
    };

    packages = forSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = self.outputs.packages.${system}.slippi.launcher;

      slippi = {
        netplay = pkgs.callPackage packages/netplay.nix {};
        playback = pkgs.callPackage packages/playback.nix {};
        launcher = pkgs.callPackage packages/launcher.nix {};
      };
    });

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
          slippi.launcher
        ];
      };

      slippi = {
        launcher = import ./modules/home-manager/slippi/launcher.nix {slippi = system: self.outputs.packages.${system}.slippi;};
      };
    };
  };
}
