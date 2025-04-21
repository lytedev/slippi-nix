let
  # static package defaults
  defaults = {
    pname = "slippi-launcher";
    inherit ((import ../hashes.nix).launcher) version hash;
  };
in
{
  lib,
  appimageTools,
  fetchurl,
  makeWrapper,
  version ? defaults.version,
  hash ? defaults.hash,
  pname ? defaults.pname,
}:
let
  # dynamic package defaults
  src = fetchurl {
    inherit hash;
    url = "https://github.com/project-slippi/slippi-launcher/releases/download/v${version}/Slippi-Launcher-${version}-x86_64.AppImage";
  };
  appImageContents = appimageTools.extract {
    inherit pname src version;
  };
in
(import ./common.nix) {
  inherit
    lib
    appimageTools
    makeWrapper
    version
    pname
    src
    appImageContents
    ;
  extraInstallCommands = ''
    wrapProgram "$out/bin/${pname}" \
      --inherit-argv0 \
      --set QT_QPA_PLATFORM xcb
    mkdir -p "$out/share/applications"
    cp -r "${appImageContents}/$(readlink "${appImageContents}/slippi-launcher.png")" "$out/share/applications/"

    sed -e '/Icon/d' -e '/Exec/d' "${appImageContents}/slippi-launcher.desktop" > "$out/share/applications/slippi-launcher.desktop"
    echo "Icon=$out/share/applications/slippi-launcher.png" >> "$out/share/applications/slippi-launcher.desktop"
    echo "Exec=$out/bin/${pname} %U" >> "$out/share/applications/slippi-launcher.desktop"
  '';
}
