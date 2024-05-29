{
  stdenvNoCC,
  appimageTools,
  fetchurl,
}: let
  pname = "Slippi_Online-x86_64.AppImage";
  version = "3.4.0";
  src = fetchurl {
    url = "https://github.com/project-slippi/Ishiiruka/releases/download/v${version}/Slippi_Online-x86_64.AppImage";
    hash = "sha256-phqQvVWrUu0jLE+exWTgRLM8RSUWCZ0RsBSXo2pP3SA=";
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

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin"
      cp -r "$src/bin" "$out"

      runHook postInstall
    '';
  }
