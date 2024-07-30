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
      slippi-netplay = {
        stdenvNoCC,
        appimageTools,
        fetchurl,
        version ? "3.4.2",
        hash ? "sha256-YXvSN+4NOvTuWErdOSEHBbP6rVsvNJCsJZu5C4VCH40=",
      }: let
        pname = "Slippi_Online-x86_64.AppImage";
        src = fetchurl {
          inherit hash;
          url = "https://github.com/project-slippi/Ishiiruka/releases/download/v${version}/Slippi_Online-x86_64.AppImage";
        };
      in
        stdenvNoCC.mkDerivation {
          inherit pname version;

          src = appimageTools.wrapType2 {
            inherit pname version src;
            extraPkgs = pkgs: with pkgs; [curl zlib mpg123];

            postInstall = ''
              ls -la "$out"
              wrapProgram $out/bin/${pname}-${version} \
                --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
            '';
          };

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/bin"
            cp -r "$src/bin" "$out"

            runHook postInstall
          '';
        };
      slippi-playback = {
        stdenvNoCC,
        appimageTools,
        fetchzip,
        version ? "3.4.3",
        hash ? "sha256-QsvayemrIztHSVcFh0I1/SOCoO6EsSTItrRQgqTWvG4=",
      }: let
        pname = "Slippi_Playback-x86_64.AppImage";
        zip = fetchzip {
          inherit hash;
          url = "https://github.com/project-slippi/Ishiiruka-Playback/releases/download/v${version}/playback-${version}-Linux.zip";
          stripRoot = false;
        };
        src = "${zip}/Slippi_Playback-x86_64.AppImage";
      in
        stdenvNoCC.mkDerivation {
          inherit pname version;

          src = appimageTools.wrapType2 {
            inherit pname version src;
            extraPkgs = pkgs: with pkgs; [curl zlib mpg123];

            postInstall = ''
              ls -la "$out"
              wrapProgram $out/bin/${pname}-${version} \
                --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
            '';
          };

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/bin"
            cp -r "$src/bin" "$out"

            runHook postInstall
          '';
        };
      slippi-launcher = {
        stdenvNoCC,
        appimageTools,
        fetchurl,
        copyDesktopItems,
        version ? "2.11.6",
        hash ? "sha256-pdBPCQ0GL7TFM5o48noc6Tovmeq+f2M3wpallems8aE=",
      }: let
        pname = "slippi-launcher-appimage";

        src = fetchurl {
          inherit hash;
          url = "https://github.com/project-slippi/slippi-launcher/releases/download/v${version}/Slippi-Launcher-${version}-x86_64.AppImage";
        };

        appImageContents = appimageTools.extractType2 {
          inherit pname version src;
        };
      in
        stdenvNoCC.mkDerivation {
          inherit pname version;

          src = appimageTools.wrapType2 {
            inherit pname version src;
            extraPkgs = pkgs: with pkgs; [curl zlib mpg123];

            postInstall = ''
              ls -la "$out"
              wrapProgram $out/bin/${pname}-${version} \
                --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
            '';
          };

          # TODO: see if we can convince upstream to let us specify command line
          # arguments to denote where the netplay and playback binaries are?
          # this might eliminate the need for the home manager module
          installPhase = ''
            runHook preInstall

            mkdir -p "$out/bin"
            mkdir -p "$out/share/applications"
            cp -r "$src/bin" "$out"
            cp -r "${appImageContents}/$(readlink "${appImageContents}/slippi-launcher.png")" "$out/share/applications/"
            sed '/Icon/d' "${appImageContents}/slippi-launcher.desktop" > "$out/share/applications/slippi-launcher.desktop"
            sed '/Exec/d' "${appImageContents}/slippi-launcher.desktop" > "$out/share/applications/slippi-launcher.desktop"
            echo "Icon=$out/share/applications/slippi-launcher.png" >> "$out/share/applications/slippi-launcher.desktop"
            echo "Exec=$out/bin/${pname} %U" >> "$out/share/applications/slippi-launcher.desktop"

            runHook postInstall
          '';

          nativeBuildInputs = [copyDesktopItems];
        };
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

      gamecube-controller-adapter = {
        lib,
        config,
        ...
      }: let
        inherit (lib) mkEnableOption mkOption types mkIf;
        cfg = config.gamecube-controller-adapter;
      in {
        # defaults here are true since we assume if you're importing the module, you
        # want it on ;)
        options.gamecube-controller-adapter = {
          enable = mkEnableOption "Enable the optimal gamecube controller adapter experience." // {default = true;};

          overclocking-kernel-module.enable = mkEnableOption "Turn on gamecube controller adapter overclocking kernel module." // {default = true;};

          udev-rules.enable = mkEnableOption "Turn on udev rules for your gamecube controller adapter." // {default = true;};
          udev-rules.rules = mkOption {
            default = ''
              ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", MODE="666", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device" TAG+="uaccess"
            '';
            type = types.lines;
            description = "To be appended to services.udev.extraRules if gcc.rules.enable is set.";
          };
        };

        config = {
          gamecube-controller-adapter.udev-rules.enable = mkIf cfg.enable true;
          gamecube-controller-adapter.overclocking-kernel-module.enable = mkIf cfg.enable true;

          services.udev.extraRules = mkIf cfg.udev-rules.enable cfg.udev-rules.rules;

          boot.extraModulePackages = mkIf cfg.overclocking-kernel-module.enable [
            # https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/gcadapter-oc-kmod/default.nix
            config.boot.kernelPackages.gcadapter-oc-kmod
          ];
          boot.kernelModules = mkIf cfg.overclocking-kernel-module.enable [
            "gcadapter_oc"
          ];
        };
      };
    };

    homeManagerModules = {
      default = {
        imports = with self.outputs.homeManagerModules; [
          slippi-launcher
        ];
      };

      slippi-launcher = {
        lib,
        pkgs,
        config,
        ...
      }: let
        inherit (lib) mkEnableOption mkOption types mkIf;
        cfg = config.slippi-launcher;
        flakePackages = self.outputs.packages.${pkgs.system};
        netplay-package = version: hash: (
          flakePackages.slippi-netplay.overrideAttrs (lib.filterAttrs (_: v: v != null) {
            inherit version hash;
          })
        );
        playback-package = version: hash:
          flakePackages.slippi-playback.overrideAttrs {
            inherit version hash;
          };
      in {
        # defaults here are true since we assume if you're importing the module, you
        # want it on ;)
        options.slippi-launcher = {
          enable = mkEnableOption "Install Slippi Launcher" // {default = true;};

          netplayVersion = mkOption {
            default = null;
            type = types.nullOr types.str;
            description = "The version of Slippi Netplay to install. Will fallback to the defaults for the package if left null.";
          };
          netplayHash = mkOption {
            default = null;
            type = types.nullOr types.str;
            description = "The hash of the Slippi Netplay zip to install. Will fallback to the defaults for the package if left null.";
          };

          playbackVersion = mkOption {
            default = null;
            type = types.nullOr types.str;
            description = "The version of Slippi Playback to install. Will fallback to the defaults for the package if left null.";
          };
          playbackHash = mkOption {
            default = null;
            type = types.nullOr types.str;
            description = "The hash of the Slippi Playback zip to install. Will fallback to the defaults for the package if left null.";
          };

          isoPath = mkOption {
            default = "";
            type = types.str;
            description = "The path to an NTSC Melee ISO.";
          };

          launchMeleeOnPlay = mkEnableOption "Launch Melee in Dolphin when the Play button is pressed." // {default = true;};

          enableJukebox = mkEnableOption "Enable in-game music via Slippi Jukebox. Incompatible with WASAPI." // {default = true;};

          rootSlpPath = mkOption {
            default = "${config.home.homeDirectory}/Slippi";
            type = types.str;
            description = "The folder where your SLP replays should be saved.";
          };

          useMonthlySubfolders = mkEnableOption "Save replays to monthly subfolders";

          spectateSlpPath = mkOption {
            default = "${cfg.rootSlpPath}/Spectate";
            type = types.nullOr types.str;
            description = "The folder where spectated games should be saved.";
          };

          extraSlpPaths = mkOption {
            default = [];
            type = types.listOf types.str;
            description = "Choose any additional SLP directories that should show up in the replay browser.";
          };
        };
        config = let
          cfgNetplayPackage = netplay-package cfg.netplayVersion cfg.netplayHash;
          cfgPlaybackPackage = playback-package cfg.playbackVersion cfg.playbackHash;
        in {
          home.packages = [(mkIf cfg.enable flakePackages.slippi-launcher)];
          home.file.".config/Slippi Launcher/netplay/Slippi_Online-x86_64.AppImage" = {
            enable = cfg.enable;
            source = "${cfgNetplayPackage}/bin/Slippi_Online-x86_64.AppImage";
            recursive = false;
          };
          home.file.".config/Slippi Launcher/netplay/Sys" = {
            enable = cfg.enable;
            source = "${pkgs.fetchzip {
              url = "https://github.com/project-slippi/Ishiiruka/releases/download/v${cfg.netplayVersion}/FM-Slippi-${cfg.netplayVersion}-Linux.zip";
              hash = cfg.netplayHash;
              stripRoot = false;
            }}/Sys";
            recursive = false;
          };
          home.file.".config/Slippi Launcher/playback/Slippi_Playback-x86_64.AppImage" = {
            enable = cfg.enable;
            source = "${cfgPlaybackPackage}/bin/Slippi_Playback-x86_64.AppImage";
            recursive = false;
          };
          home.file.".config/Slippi Launcher/playback/Sys" = {
            enable = cfg.enable;
            source = "${
              pkgs.fetchzip {
                url = "https://github.com/project-slippi/Ishiiruka-Playback/releases/download/v${cfg.playbackVersion}/playback-${cfg.playbackVersion}-Linux.zip";
                hash = cfg.netplayHash;
                stripRoot = false;
              }
            }/Sys";
            recursive = false;
          };
          xdg.configFile."Slippi Launcher/Settings" = {
            enable = cfg.enable;
            source = let
              jsonFormat = pkgs.formats.json {};
            in
              jsonFormat.generate "slippi-config" {
                settings = {
                  isoPath = cfg.isoPath;

                  launchMeleeOnPlay = cfg.launchMeleeOnPlay;
                  enableJukebox = cfg.enableJukebox;

                  rootSlpPath = cfg.rootSlpPath;
                  useMonthlySubfolders = cfg.useMonthlySubfolders;
                  spectateSlpPath = cfg.spectateSlpPath;
                  extraSlpPaths = cfg.extraSlpPaths;

                  netplayDolphinPath = "${cfgNetplayPackage}/bin/";
                  playbackDolphinPath = "${cfgPlaybackPackage}/bin/";

                  autoUpdateLauncher = false;
                };
              };
          };
        };
      };
    };
  };
}
