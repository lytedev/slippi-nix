{
  fetchurl,
  callAppImage,
}:
callAppImage rec {
  pname = "slippi-netplay-appimage";
  version = "3.4.0";

  appImageSrc = fetchurl {
    url = "https://github.com/project-slippi/Ishiiruka/releases/download/v${version}/Slippi_Online-x86_64.AppImage";
    hash = "sha256-phqQvVWrUu0jLE+exWTgRLM8RSUWCZ0RsBSXo2pP3SA=";
  };

  desktop = {
    desktopName = "Slippi Netplay (AppImage)";
    comment = "Play Super Smash Bros. Melee online!";
    categories = ["Game"];
    keywords = ["slippi" "melee" "rollback"];
  };
}
