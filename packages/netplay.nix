{
  stdenvNoCC,
  appimageTools,
  fetchurl,
  version ? "3.4.1",
  hash ? "sha256-Ns0yhnb2H0wDj+vUtjSgujpVV8GjKrKSf+OoaCuXIKA=",
}: let
  pname = "Slippi_Online-x86_64.AppImage";
  src = fetchurl {
    inherit hash;
    url = "https://github.com/project-slippi/Ishiiruka/releases/download/v${version}/Slippi_Online-x86_64.AppImage";
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
