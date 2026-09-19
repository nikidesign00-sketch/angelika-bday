#!/bin/bash
# Скачивает видеостикеры пака через Bot API и делает копии с альфой для Safari.
# Токен — от любого своего бота из @BotFather:
#   TG_BOT_TOKEN=123456:ABC... ./fetch-stickers.sh
set -euo pipefail
[ -n "${TG_BOT_TOKEN:-}" ] || read -rsp "Токен бота из @BotFather: " TG_BOT_TOKEN; echo
cd "$(dirname "$0")"
API="https://api.telegram.org/bot$TG_BOT_TOKEN"

ids=$(curl -sf "$API/getStickerSet?name=imbo_fd088_by_TgEmodziBot" | python3 -c '
import json, sys
for s in json.load(sys.stdin)["result"]["stickers"]:
    assert s["is_video"], "в паке есть не-видео стикер"
    print(s["file_id"])')

mkdir -p stickers
i=0
for id in $ids; do
  path=$(curl -sf "$API/getFile?file_id=$id" | python3 -c 'import json, sys; print(json.load(sys.stdin)["result"]["file_path"])')
  curl -sf -o "stickers/$i.webm" "https://api.telegram.org/file/bot$TG_BOT_TOKEN/$path"
  # libvpx-vp9 как декодер, иначе ffmpeg теряет альфу
  ffmpeg -v error -y -c:v libvpx-vp9 -i "stickers/$i.webm" -c:v hevc_videotoolbox -allow_sw 1 \
    -alpha_quality 0.75 -q:v 55 -pix_fmt bgra -tag:v hvc1 "stickers/$i.mov"
  echo "стикер $i"
  i=$((i + 1))
done
echo "готово: $i (в index.html STICKERS = 19, поправь, если число другое)"
