{
  lib,
  appimageTools,
  makeWrapper,
  source,
}:
let
  pname = "slippi-launcher";
  inherit (source) version src;
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
    install -Dm644 "${appImageContents}/slippi-launcher.png" $out/share/icons/hicolor/512x512/apps/${pname}.png

    sed -e '/Icon/d' -e '/Exec/d' "${appImageContents}/slippi-launcher.desktop" > "$out/share/applications/slippi-launcher.desktop"
    echo "Icon=slippi-launcher" >> "$out/share/applications/slippi-launcher.desktop"
    echo "Exec=$out/bin/${pname} %U" >> "$out/share/applications/slippi-launcher.desktop"
  '';
}
