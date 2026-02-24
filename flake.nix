{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = [
      "https://slippi-nix.cachix.org"
    ];

    extra-trusted-public-keys = [
      "slippi-nix.cachix.org-1:2qnPHiOxTRpzgLEtx6K4kXq/ySDg7zHEJ58J6xNDvBo="
    ];
  };

  outputs =
    {
      nixpkgs,
      git-hooks,
      home-manager,
      self,
      ...
    }:
    let
      forSystems = nixpkgs.lib.genAttrs [
        # "aarch64-darwin"
        # "x86_64-darwin"
        # "aarch64-linux"
        "x86_64-linux"
      ];
      pkgsFor = system: (import nixpkgs { inherit system; });
      genPkgs = func: (forSystems (system: func (pkgsFor system)));
    in
    {
      overlays = {
        default = self.overlays.slippi;

        slippi = final: prev: {
          inherit (self.packages.${final.system}.slippi) slippi-netplay slippi-playback slippi-launcher;
        };
      };

      packages = genPkgs (pkgs: {
        default = self.packages.${pkgs.system}.slippi-launcher-desktop;
        slippi-netplay-beta = pkgs.callPackage ./packages/slippi-netplay-beta.nix { };
        slippi-netplay = pkgs.callPackage ./packages/slippi-netplay.nix { };
        slippi-playback = pkgs.callPackage ./packages/slippi-playback.nix { };
        slippi-launcher = pkgs.callPackage ./packages/slippi-launcher.nix { };
        slippi-launcher-desktop = pkgs.callPackage ./packages/slippi-launcher-desktop.nix {
          inherit (pkgs) formats;
          inherit (self.packages.${pkgs.system})
            slippi-launcher
            slippi-netplay
            slippi-netplay-beta
            slippi-playback
            ;
        };
      });

      formatter = genPkgs (p: p.nixfmt-rfc-style);

      nixosModules = {
        default = self.nixosModules.gamecube-controller-adapter;
        gamecube-controller-adapter = ./modules/nixos/gamecube-controller-adapter.nix;
      };

      homeManagerModules = {
        default = self.homeManagerModules.slippi-launcher;
        slippi-launcher = ./modules/home-manager;
      };

      checks = genPkgs (pkgs: {
        inherit (self.packages.${pkgs.system})
          slippi-launcher
          slippi-launcher-desktop
          slippi-netplay
          slippi-playback
          slippi-netplay-beta
          ;
        git-hooks = git-hooks.lib.${pkgs.system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style.enable = true;
          };
        };
        home-manager-module-test = pkgs.testers.runNixOSTest {
          # a simple integration test to ensure that the home manager module
          # works, boots a host, implying a successful NixOS configuration, and
          # creates the configuration file referencing the correct packages'
          # versions
          name = "home-manager-module-test";
          nodes.machine =
            {
              pkgs,
              ...
            }:
            with pkgs.lib;
            {
              imports = [
                home-manager.nixosModules.home-manager
                "${nixpkgs}/nixos/tests/common/auto.nix"
                "${nixpkgs}/nixos/tests/common/x11.nix"
              ];
              users.users.daniel = {
                isNormalUser = true;
                home = "/home/daniel";
                createHome = true;
                extraGroups = [
                  "wheel"
                  "users"
                ];
              };
              test-support.displayManager.auto.user = "daniel";
              home-manager.users.daniel = {
                imports = with self.homeManagerModules; [
                  slippi-launcher
                ];
                slippi-launcher.enable = true;
                home = {
                  username = "daniel";
                  homeDirectory = "/home/daniel";
                  stateVersion = "25.05";
                };
              };
              environment.systemPackages = with pkgs; [ jq ];
              system.stateVersion = "25.05";
            };
          testScript =
            # nodes,
            { ... }:
            let
              hashes = import ./hashes.nix;
            in
            ''
              def as_user(cmd: str):
                  """
                  Return a shell command for running a shell command as a specific user.
                  """
                  return f"sudo -u daniel -i -- bash -c \"{cmd}\""

              with subtest("ensure slippi launcher settings file references correct versions"):
                  machine.wait_for_unit("default.target")
                  machine.succeed("grep ${hashes.netplay.version} '/home/daniel/.config/Slippi Launcher/Settings'")
                  machine.succeed("grep ${hashes.playback.version} '/home/daniel/.config/Slippi Launcher/Settings'")

              with subtest("ensure netplay appimage version is correct"):
                  machine.wait_for_unit("default.target")
                  machine.wait_for_x()
                  machine.wait_for_file("/home/daniel/.Xauthority")
                  machine.succeed("xauth merge /home/daniel/.Xauthority")
                  machine.succeed(as_user("""
                  "''$(jq -r '.settings.netplayDolphinPath' '/home/daniel/.config/Slippi Launcher/Settings')/Slippi_Online-x86_64.AppImage" --version | grep ${hashes.netplay.version}
                  """))
            '';
        };
      });
    };
}
