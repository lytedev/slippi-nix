# nvfetcher can only emit `fetchurl`, so the Slippi `-Linux.zip` release assets
# arrive as a raw archive. This unpacks one into the same top-level tree that
# `fetchzip { stripRoot = false; }` used to produce: the AppImage alongside the
# `Sys/` data directory the launcher symlinks into its config.
{
  runCommand,
  unzip,
  name,
  src,
}:
runCommand "${name}-unpacked" { nativeBuildInputs = [ unzip ]; } ''
  mkdir -p "$out"
  unzip -q "${src}" -d "$out"
''
