{
  fetchurl,
  callAppImage,
}:
callAppImage rec {
  # TODO: see if we can convince upstream to let us specify command line
  # arguments to denote where the netplay and playback binaries are?
  # this might eliminate the need for the home manager module
  pname = "slippi-launcher-appimage";
  version = "2.11.6";

  appImageSrc = fetchurl {
    url = "https://github.com/project-slippi/slippi-launcher/releases/download/v${version}/Slippi-Launcher-${version}-x86_64.AppImage";
    hash = "sha256-pdBPCQ0GL7TFM5o48noc6Tovmeq+f2M3wpallems8aE=";
  };

  desktop = {
    desktopName = "Slippi Launcher (AppImage)";
    comment = "The way to play Slippi Online and watch replays";
    categories = ["Game"];
    keywords = ["slippi" "melee" "rollback"];
  };
}
