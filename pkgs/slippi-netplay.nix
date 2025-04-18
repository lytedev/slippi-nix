let
  hashes = import ../hashes.nix;
in
  {
    appimageTools,
    fetchzip,
    makeWrapper,
    version ? hashes.netplay.version,
    hash ? hashes.netplay.hash,
  }:
    appimageTools.wrapType2 rec {
      pname = "Slippi_Online-x86_64.AppImage";
      inherit version;
      nativeBuildInputs = [
        makeWrapper
      ];

      rawZip = fetchzip {
        inherit hash;
        url = "https://github.com/project-slippi/Ishiiruka/releases/download/v${version}/FM-Slippi-${version}-Linux.zip";
        stripRoot = false;
      };
      src = "${rawZip}/Slippi_Online-x86_64.AppImage";

      extraInstallCommands = ''
        wrapProgram "$out/bin/${pname}" \
          --inherit-argv0 \
          --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"
      '';

      extraPkgs = pkgs: with pkgs; [curl zlib mpg123];

      passthru.raw-zip = rawZip;
    }
