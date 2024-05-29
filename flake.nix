{
  inputs.nixpkgs.url = "";

  outputs = inputs: let
    forSystems = inputs.nixpkgs.lib.genAttrs ["aarch64-linux" "aarch64-darwin" "x86_64-darwin" "x86_64-linux"];
    pkgsFor = system: (import inputs.nixpkgs {inherit system;});
  in {
    packages = forSystems (system: let
      pkgs = pkgsFor system;
    in {
      slippi = {
        netplay = pkgs.callPackage ./netplay.nix {};
      };
    });
  };
}
