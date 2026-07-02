{
  lib,
  appimageTools,
  makeWrapper,
  runCommand,
  unzip,
  source,
}:
let
  pname = "Slippi_Online-x86_64.AppImage";
  rawZip = import ./unpack-appimage-zip.nix {
    inherit runCommand unzip;
    name = "slippi-netplay-${source.version}";
    inherit (source) src;
  };
  src = "${rawZip}/Slippi_Online-x86_64.AppImage";
in
(import ./common.nix) {
  inherit
    lib
    appimageTools
    makeWrapper
    pname
    src
    rawZip
    ;
  inherit (source) version;
  extraInstallCommands = ''
    wrapProgram "$out/bin/${pname}" \
      --inherit-argv0
  '';
}
