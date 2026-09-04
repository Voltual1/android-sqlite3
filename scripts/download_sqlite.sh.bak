#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/sqlite-version.env"

ZIP_NAME="sqlite-amalgamation-${SQLITE_VERSION_NUMBER}.zip"
URL="https://www.sqlite.org/${SQLITE_YEAR}/${ZIP_NAME}"
DOWNLOAD_DIR="$ROOT_DIR/downloads"
BUILD_DIR="$ROOT_DIR/build"
ZIP_PATH="$DOWNLOAD_DIR/$ZIP_NAME"

mkdir -p "$DOWNLOAD_DIR" "$BUILD_DIR"

if [[ ! -f "$ZIP_PATH" ]]; then
  curl -L --fail --show-error -o "$ZIP_PATH" "$URL"
fi

ACTUAL_SHA3="$(openssl dgst -sha3-256 "$ZIP_PATH" | awk '{print $NF}')"
if [[ "$ACTUAL_SHA3" != "$SQLITE_AMALGAMATION_SHA3_256" ]]; then
  echo "SHA3 mismatch for $ZIP_NAME" >&2
  echo "expected: $SQLITE_AMALGAMATION_SHA3_256" >&2
  echo "actual:   $ACTUAL_SHA3" >&2
  exit 1
fi

unzip -q -o "$ZIP_PATH" -d "$BUILD_DIR"
echo "$BUILD_DIR/sqlite-amalgamation-${SQLITE_VERSION_NUMBER}"

