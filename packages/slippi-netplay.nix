let
  # static package defaults
  defaults = {
    pname = "Slippi_Online-x86_64.AppImage";
    inherit ((import ../hashes.nix).netplay) version hash;
  };
in
{
  lib,
  appimageTools,
  makeWrapper,
  fetchzip,
  version ? defaults.version,
  hash ? defaults.hash,
  pname ? defaults.pname,
}:
let
  _logHash = (builtins.trace "Slippi Netplay Hash: ${hash}" hash);
  _logVersion = (builtins.trace "Slippi Netplay Version: ${version}" version);
  _logUrl = "https://github.com/project-slippi/Ishiiruka/releases/download/v${_logVersion}/FM-Slippi-${_logVersion}-Linux.zip";
  # dynamic package defaults
  rawZip = fetchzip {
    hash = _logHash;
    url = builtins.trace "Slippi Netplay Zip URL: ${_logUrl}" _logUrl;
    stripRoot = false;
  };
  src = "${rawZip}/Slippi_Online-x86_64.AppImage";
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
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
  '';
}
