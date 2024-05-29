{
  fetchzip,
  callAppImage,
}: let
  version = "3.4.1";
  zip = fetchzip {
    url = "https://github.com/project-slippi/Ishiiruka-Playback/releases/download/v${version}/playback-${version}-Linux.zip";
    hash = "sha256-d1iawMsMwFElUqFmwWAD9rNsDdQr2LKscU8xuJPvxYg=";
    stripRoot = false;
  };
in
  callAppImage {
    inherit version;
    pname = "slippi-playback-appimage";

    appImageSrc = "${zip}/Slippi_Playback-x86_64.AppImage";

    desktop = {
      desktopName = "Slippi Netplay (AppImage)";
      comment = "Play Super Smash Bros. Melee online!";
      categories = ["Game"];
      keywords = ["slippi" "melee" "rollback"];
    };
  }
