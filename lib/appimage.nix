{
  stdenvNoCC,
  appimageTools,
  fetchurl,
  makeDesktopItem,
  copyDesktopItems,
  makeWrapper,
  pkg-config,
}: {
  pname,
  version,
  appImageSrc,
  desktop,
}:
stdenvNoCC.mkDerivation rec {
  inherit pname version;

  src = appimageTools.wrapType2 {
    inherit pname version;

    src = appImageSrc;

    extraPkgs = ppkgs: with ppkgs; [curl zlib mpg123];

    postInstall = ''
      wrapProgram $out/bin/${pname}-${version} \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
    '';
  };

  desktopItems = [
    (
      makeDesktopItem ({
          name = pname;
          exec = "${pname}-${version} %U";
          icon = "${pname}";
          type = "Application";
        }
        // desktop)
      /*
      desktopName = desktop.name;
      comment = desktop.comment;
      categories = ["Game"];
      keywords = ["slippi" "melee" "rollback"];
      */
    )
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cp -r "$src/bin" "$out"

    runHook postInstall
  '';

  nativeBuildInputs = [copyDesktopItems];
}
