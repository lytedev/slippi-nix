{
  stdenvNoCC,
  appimageTools,
  fetchurl,
  makeDesktopItem,
  copyDesktopItems,
  # makeWrapper,
}:
stdenvNoCC.mkDerivation rec {
  pname = "slippi-netplay-appimage";
  version = "3.4.0";

  src = appimageTools.wrapType2 {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/project-slippi/Ishiiruka/releases/download/v${version}/Slippi_Online-x86_64.AppImage";
      hash = "sha256-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    };

    # extraInstallCommands = ''
    #   source "${makeWrapper}/nix-support/setup-hook"
    #   wrapProgram $out/bin/slippi-launcher-${version} \
    #     --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
    # '';
  };

  desktopItems = [
    (makeDesktopItem {
      name = "slippi-netplay-appimage";
      exec = "slippi-netplay-appimage-${version}";
      icon = "slippi-netplay-appimage";
      desktopName = "Slippi Netplay (AppImage)";
      comment = "Play Slippi Online";
      type = "Application";
      categories = ["Game"];
      keywords = ["slippi" "melee" "rollback"];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cp -r "$src/bin" "$out"

    runHook postInstall
  '';

  nativeBuildInputs = [copyDesktopItems];
}
