let
  hashes = import ../hashes.nix;
in
  {
    appimageTools,
    fetchurl,
    makeWrapper,
    version ? hashes.launcher.version,
    hash ? hashes.launcher.hash,
  }:
    appimageTools.wrapType2 rec {
      pname = "slippi-launcher";
      inherit version;
      nativeBuildInputs = [
        makeWrapper
      ];
      src = fetchurl {
        inherit hash;
        url = "https://github.com/project-slippi/slippi-launcher/releases/download/v${version}/Slippi-Launcher-${version}-x86_64.AppImage";
      };

      appImageContents = appimageTools.extract {
        inherit pname src version;
      };
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

      extraPkgs = pkgs: with pkgs; [curl zlib mpg123];
    }
