# A wrapped slippi-launcher that works standalone (without the Home Manager
# module) by seeding the config directory with correct Dolphin paths and
# AppImage symlinks on each launch.
{
  lib,
  writeShellApplication,
  jq,
  slippi-launcher,
  slippi-netplay,
  slippi-netplay-beta,
  slippi-playback,
  formats,
}:
let
  managedSettings = (formats.json { }).generate "slippi-managed-settings" {
    settings = {
      netplayDolphinPath = "${slippi-netplay}/bin/";
      playbackDolphinPath = "${slippi-playback}/bin/";
      autoUpdateLauncher = false;
    };
  };
in
writeShellApplication {
  name = "slippi-launcher";
  runtimeInputs = [ jq ];
  text = ''
    slippi_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/Slippi Launcher"
    settings="$slippi_dir/Settings"

    mkdir -p "$slippi_dir/netplay" "$slippi_dir/netplay-beta" "$slippi_dir/playback"

    # Symlink Nix-wrapped AppImages and Sys directories so the launcher
    # can detect versions and Dolphin can find its system files.
    ln -sfn ${lib.getExe slippi-netplay} "$slippi_dir/netplay/Slippi_Online-x86_64.AppImage"
    ln -sfn ${slippi-netplay.raw-zip}/Sys "$slippi_dir/netplay/Sys"
    ln -sfn ${lib.getExe slippi-netplay-beta} "$slippi_dir/netplay-beta/Slippi_Netplay_Mainline-x86_64.AppImage"
    ln -sfn ${slippi-netplay-beta.raw-zip}/Sys "$slippi_dir/netplay-beta/Sys"
    ln -sfn ${lib.getExe slippi-playback} "$slippi_dir/playback/Slippi_Playback-x86_64.AppImage"
    ln -sfn ${slippi-playback.raw-zip}/Sys "$slippi_dir/playback/Sys"

    # Remove stale symlink from older module versions
    if [ -L "$settings" ]; then
      rm "$settings"
    fi

    if [ -f "$settings" ]; then
      # Merge Nix-managed settings on top of existing (Nix paths win)
      jq -s '.[0] * .[1]' "$settings" ${managedSettings} > "$settings.tmp"
      mv "$settings.tmp" "$settings"
    else
      cp ${managedSettings} "$settings"
      chmod u+w "$settings"
    fi

    exec ${lib.getExe slippi-launcher} "$@"
  '';

  meta = slippi-launcher.meta // {
    description = "Slippi Launcher (standalone, pre-configured for NixOS)";
  };
}
