{
  stdenvNoCC,
  appimageTools,
  fetchurl,
  copyDesktopItems,
}: let
  pname = "slippi-launcher-appimage";
  version = "2.11.6";

  src = fetchurl {
    url = "https://github.com/project-slippi/slippi-launcher/releases/download/v${version}/Slippi-Launcher-${version}-x86_64.AppImage";
    hash = "sha256-pdBPCQ0GL7TFM5o48noc6Tovmeq+f2M3wpallems8aE=";
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
      echo "Icon=$out/share/applications/slippi-launcher.png" >> "$out/share/applications/slippi-launcher.desktop"

      runHook postInstall
    '';

    nativeBuildInputs = [copyDesktopItems];
  }
