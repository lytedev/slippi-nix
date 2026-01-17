{
  lib,
  appimageTools,
  makeWrapper,
  version,
  pname,
  src,
  extraInstallCommands,
  appImageContents ? null,
  rawZip ? null,
}:
appimageTools.wrapType2 (
  {
    version = builtins.trace "${pname} version: ${version}" version;
    inherit
      pname
      src
      appImageContents
      extraInstallCommands
      ;
    nativeBuildInputs = [ makeWrapper ];
    extraPkgs =
      pkgs: with pkgs; [
        curl
        zlib
        mpg123
      ];
    meta.mainProgram = pname;
  }
  // lib.optionalAttrs (rawZip != null) {
    passthru.raw-zip = rawZip;
  }
  // lib.optionalAttrs (appImageContents != null) {
    inherit appImageContents;
  }
)
