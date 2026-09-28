#!/usr/bin/env bash
# Builds dist/StealAnimeEgg_UI_Lab_COMPLETE.zip (Roblox packages + Rojo source +
# SVG/PNG assets + preview + docs + tools). Run after `node build.js`.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=dist/StealAnimeEgg_UI_Lab_COMPLETE.zip
rm -f "$OUT"
STAGE=$(mktemp -d)
DEST="$STAGE/StealAnimeEgg-UI-Lab"
mkdir -p "$DEST/dist"
cp dist/StealAnimeEgg_UI_Lab.rbxmx dist/StealAnimeEgg_UI_Lab.rbxm dist/StealAnimeEgg_UI_Lab_Demo.rbxlx "$DEST/dist/"
cp -r src assets preview docs "$DEST/"
mkdir -p "$DEST/tools"
( cd tools && tar cf - --exclude=node_modules . ) | ( cd "$DEST/tools" && tar xf - )
cp README.md default.project.json package.project.json selene.toml "$DEST/"
( cd "$STAGE" && zip -qr -9 "$OLDPWD/$OUT" StealAnimeEgg-UI-Lab )
rm -rf "$STAGE"
echo "wrote $OUT ($(du -h "$OUT" | cut -f1))"
unzip -l "$OUT" | tail -1
