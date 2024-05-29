slippiClosure: {
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.slippi.launcher;
  slippi-packages = slippiClosure pkgs.system;
in {
  # defaults here are true since we assume if you're importing the module, you
  # want it on ;)
  options.slippi.launcher = {
    enable = mkEnableOption "Install Slippi Launcher" // {default = true;};

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

    # TODO: I don't think these are actually used any longer.
    # Let's mark this field as deprecated?
    netplayDolphinPath = mkOption {
      default = "${slippi-packages.netplay}/bin/";
      type = types.str;
      description = "The path to the folder containing the Netplay Dolphin Executable";
    };

    # TODO: I don't think these are actually used any longer.
    # Let's mark this field as deprecated?
    playbackDolphinPath = mkOption {
      default = "${slippi-packages.playback}/bin/";
      type = types.str;
      description = "The path to the folder containing the Playback Dolphin Executable";
    };
  };
  config = {
    home.packages = [(mkIf cfg.enable slippi-packages.launcher)];
    home.file.".config/Slippi Launcher/netplay" = {
      enable = true;
      source = "${slippi-packages.netplay}/bin/";
      recursive = false;
    };
    home.file.".config/Slippi Launcher/playback" = {
      enable = true;
      source = "${slippi-packages.playback}/bin/";
      recursive = false;
    };
    home.file.".config/Slippi Launcher/poopoobutt" = {
      enable = true;
      text = "wth is happening";
    };
    xdg.configFile."Slippi Launcher/Settings".source = let
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

          netplayDolphinPath = cfg.netplayDolphinPath;

          playbackDolphinPath = cfg.playbackDolphinPath;

          autoUpdateLauncher = false;
        };
      };
  };
}
