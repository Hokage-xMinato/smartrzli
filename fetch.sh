#!/usr/bin/env bash
set -euo pipefail

TOKEN_URL='https://rolexcoderz.in/api/get-token'
CONTENT_URL='https://rolexcoderz.in/api/get-live-classes'
UA='Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36'
REFERER='https://rolexcoderz.in/live-classes'

write_error_json() {
    printf '{"status":false, "error":"%s", "errorCode":"%s"}\n' "$2" "$3" > "$1"
}

fetch_and_decode_content() {
    local TYPE="$1"
    local PAYLOAD="{\"type\":\"$TYPE\"}"
    local OUTPUT_FILE="output_${TYPE}.json"

    resp=$(curl -s "$TOKEN_URL" -H "User-Agent: $UA" -H "Referer: $REFERER" --compressed)
    ts=$(echo "$resp" | grep -oP '"timestamp":\K[0-9]+' || true)
    sig=$(echo "$resp" | grep -oP '"signature":"\K[a-f0-9]+' || true)

    [[ -z "$ts" || -z "$sig" ]] && { write_error_json "$OUTPUT_FILE" "Token fetch failed" "TOKEN_FAILED"; return; }

    TEMP=$(mktemp)
    curl -s "$CONTENT_URL" -H 'Content-Type: application/json' \
         -H "x-timestamp: $ts" -H "x-signature: $sig" \
         -H "User-Agent: $UA" -H "Referer: $REFERER" \
         --data-raw "$PAYLOAD" --compressed -o "$TEMP"

    b64=$(grep -oP '"data":"\K[^"]+' "$TEMP" || true)
    [[ -z "$b64" ]] && { write_error_json "$OUTPUT_FILE" "No Base64 data" "NO_DATA"; rm "$TEMP"; return; }

    echo "$b64" | base64 --decode > "$OUTPUT_FILE" || { write_error_json "$OUTPUT_FILE" "Decode error" "DECODE_FAIL"; rm "$TEMP"; return; }

    sed -i 's|https://www.rolexcoderz.xyz/Player/?url=||gI' "$OUTPUT_FILE"
    sed -i 's/rolex coderz/smartrz/gI' "$OUTPUT_FILE"
    sed -i 's/rolexcoderz\.xyz/smartrz/gI' "$OUTPUT_FILE"
    sed -i 's/rolexcoderz/smartrz/gI' "$OUTPUT_FILE"

    rm "$TEMP"
}

fetch_and_decode_content "live"
fetch_and_decode_content "up"
fetch_and_decode_content "completed"
