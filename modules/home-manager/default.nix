{
  lib,
  pkgs,
  config,
  ...
}:
let
  hashes = import ../../hashes.nix;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    ;
  cfg = config.slippi-launcher;
  netplay-beta-package =
    version: hash:
    pkgs.callPackage ../../packages/slippi-netplay-beta.nix {
      inherit version hash;
    };
  netplay-package =
    version: hash:
    pkgs.callPackage ../../packages/slippi-netplay.nix {
      inherit version hash;
    };
  playback-package =
    version: hash:
    pkgs.callPackage ../../packages/slippi-playback.nix {
      inherit version hash;
    };
  launcher-package =
    version: hash:
    pkgs.callPackage ../../packages/slippi-launcher.nix {
      inherit version hash;
    };
in
{
  options.slippi-launcher = {
    enable = mkEnableOption "Install Slippi Launcher" // {
      default = true;
    };

    netplayVersion = mkOption {
      default = hashes.netplay.version;
      type = types.str;
      description = "The version of Slippi Netplay to install.";
    };
    netplayHash = mkOption {
      default = hashes.netplay.hash;
      type = types.str;
      description = "The hash of the Slippi Netplay AppImage to install.";
    };

    netplayBetaVersion = mkOption {
      default = hashes.netplay-beta.version;
      type = types.str;
      description = "The version of Slippi Netplay (Mainline beta) to install.";
    };
    netplayBetaHash = mkOption {
      default = hashes.netplay-beta.hash;
      type = types.str;
      description = "The hash of the Slippi Netplay (Mainline beta) AppImage to install.";
    };

    playbackVersion = mkOption {
      default = hashes.playback.version;
      type = types.str;
      description = "The version of Slippi Playback to install.";
    };
    playbackHash = mkOption {
      default = hashes.playback.hash;
      type = types.str;
      description = "The hash of the Slippi Playback AppImage to install.";
    };

    launcherVersion = mkOption {
      default = hashes.launcher.version;
      type = types.str;
      description = "The version of Slippi Launcher to install.";
    };
    launcherHash = mkOption {
      default = hashes.launcher.hash;
      type = types.str;
      description = "The hash of the Slippi Launcher AppImage to install.";
    };

    isoPath = mkOption {
      default = "";
      type = types.str;
      description = "The path to an NTSC Melee ISO.";
    };
    useNetplayBeta = mkEnableOption "Use the mainline Dolphin instead of the stable version." // {
      default = false;
    };

    launchMeleeOnPlay = mkEnableOption "Launch Melee in Dolphin when the Play button is pressed." // {
      default = true;
    };

    enableJukebox =
      mkEnableOption "Enable in-game music via Slippi Jukebox. Incompatible with WASAPI."
      // {
        default = true;
      };

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
      default = [ ];
      type = types.listOf types.str;
      description = "Choose any additional SLP directories that should show up in the replay browser.";
    };
  };
  config = mkIf cfg.enable (
    let
      cfgNetplayPackage = netplay-package cfg.netplayVersion cfg.netplayHash;
      cfgNetplayBetaPackage = netplay-beta-package cfg.netplayBetaVersion cfg.netplayBetaHash;
      cfgPlaybackPackage = playback-package cfg.playbackVersion cfg.playbackHash;
      cfgLauncherPackage = launcher-package cfg.launcherVersion cfg.launcherHash;
    in
    {
      home.packages = [ cfgLauncherPackage ];
      home.file.".config/Slippi Launcher/netplay/Slippi_Online-x86_64.AppImage" = {
        source = "${lib.getExe cfgNetplayPackage}";
        recursive = false;
      };
      home.file.".config/Slippi Launcher/netplay/Sys" = {
        source = "${cfgNetplayPackage.raw-zip}/Sys";
        recursive = false;
      };
      home.file.".config/Slippi Launcher/netplay-beta/Slippi_Netplay_Mainline-x86_64.AppImage" = {
        source = "${lib.getExe cfgNetplayBetaPackage}";
        recursive = false;
      };
      home.file.".config/Slippi Launcher/netplay-beta/Sys" = {
        source = "${cfgNetplayBetaPackage.raw-zip}/Sys";
        recursive = false;
      };
      home.file.".config/Slippi Launcher/playback/Slippi_Playback-x86_64.AppImage" = {
        source = "${lib.getExe cfgPlaybackPackage}";
        recursive = false;
      };
      home.file.".config/Slippi Launcher/playback/Sys" = {
        source = "${cfgPlaybackPackage.raw-zip}/Sys";
        recursive = false;
      };
      # Use an activation script instead of xdg.configFile so the settings
      # file is mutable. The launcher needs to write to it (e.g. login
      # credentials). Nix-managed settings are merged on each activation,
      # preserving any extra keys the launcher has written.
      home.activation.slippiLauncherSettings =
        let
          jsonFormat = pkgs.formats.json { };
          settingsFile = jsonFormat.generate "slippi-config" {
            settings = {
              isoPath = cfg.isoPath;

              launchMeleeOnPlay = cfg.launchMeleeOnPlay;
              enableJukebox = cfg.enableJukebox;
              useNetplayBeta = cfg.useNetplayBeta;

              rootSlpPath = cfg.rootSlpPath;
              useMonthlySubfolders = cfg.useMonthlySubfolders;
              spectateSlpPath = cfg.spectateSlpPath;
              extraSlpPaths = cfg.extraSlpPaths;

              netplayDolphinPath = "${
                if cfg.useNetplayBeta then cfgNetplayBetaPackage else cfgNetplayPackage
              }/bin/";
              playbackDolphinPath = "${cfgPlaybackPackage}/bin/";

              autoUpdateLauncher = false;
            };
          };
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          slippi_dir="${config.xdg.configHome}/Slippi Launcher"
          slippi_settings="$slippi_dir/Settings"

          mkdir -p "$slippi_dir"

          # Remove stale symlink from previous module version
          if [ -L "$slippi_settings" ]; then
            rm "$slippi_settings"
          fi

          if [ -f "$slippi_settings" ]; then
            # Merge existing settings with Nix-managed settings (Nix wins on conflicts)
            ${pkgs.jq}/bin/jq -s '.[0] * .[1]' \
              "$slippi_settings" \
              "${settingsFile}" > "$slippi_settings.tmp"
            mv "$slippi_settings.tmp" "$slippi_settings"
          else
            cp "${settingsFile}" "$slippi_settings"
            chmod u+w "$slippi_settings"
          fi
        '';
    }
  );
}
