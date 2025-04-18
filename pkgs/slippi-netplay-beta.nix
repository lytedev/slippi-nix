let
  hashes = import ../hashes.nix;
in
  {
    appimageTools,
    fetchzip,
    makeWrapper,
    version ? hashes.netplay-beta.version,
    hash ? hashes.netplay-beta.hash,
  }:
    appimageTools.wrapType2 rec {
      pname = "Slippi_Netplay_Mainline-x86_64.AppImage";
      inherit version;
      nativeBuildInputs = [
        makeWrapper
      ];
      rawZip = fetchzip {
        inherit hash;
        url = "https://github.com/project-slippi/dolphin/releases/download/v${version}/Mainline-Slippi-${version}-Linux.zip";
        stripRoot = false;
      };
      src = "${rawZip}/Slippi_Netplay_Mainline-x86_64.AppImage";
      extraInstallCommands = ''
        wrapProgram "$out/bin/${pname}" \
          --inherit-argv0 \
          --set QT_QPA_PLATFORM xcb
      '';

      extraPkgs = pkgs: with pkgs; [curl zlib mpg123];

      passthru.raw-zip = rawZip;
    }
