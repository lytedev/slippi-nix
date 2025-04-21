let
  # static package defaults
  defaults = {
    pname = "Slippi_Netplay_Mainline-x86_64.AppImage";
    inherit ((import ../hashes.nix).netplay-beta) version hash;
  };
in
{
  lib,
  appimageTools,
  fetchzip,
  makeWrapper,
  version ? defaults.version,
  hash ? defaults.hash,
  pname ? defaults.pname,
}:
let
  # dynamic package defaults
  rawZip = fetchzip {
    inherit hash;
    url = "https://github.com/project-slippi/dolphin/releases/download/v${version}/Mainline-Slippi-${version}-Linux.zip";
    stripRoot = false;
  };
  src = "${rawZip}/Slippi_Netplay_Mainline-x86_64.AppImage";
in
(import ./common.nix) {
  inherit
    lib
    appimageTools
    makeWrapper
    version
    pname
    src
    rawZip
    ;
  extraInstallCommands = ''
    wrapProgram "$out/bin/${pname}" \
      --inherit-argv0 \
      --set QT_QPA_PLATFORM xcb
  '';
}
