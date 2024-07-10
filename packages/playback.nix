{
  stdenvNoCC,
  appimageTools,
  fetchzip,
  version ? "3.4.3",
  hash ? "sha256-QsvayemrIztHSVcFh0I1/SOCoO6EsSTItrRQgqTWvG4=",
}: let
  pname = "Slippi_Playback-x86_64.AppImage";
  zip = fetchzip {
    inherit hash;
    url = "https://github.com/project-slippi/Ishiiruka-Playback/releases/download/v${version}/playback-${version}-Linux.zip";
    stripRoot = false;
  };
  src = "${zip}/Slippi_Playback-x86_64.AppImage";
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
