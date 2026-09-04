#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/sqlite-version.env"

API_LEVEL="${API_LEVEL:-23}"
SOURCE_DIR="${SOURCE_DIR:-$ROOT_DIR/build/sqlite-amalgamation-${SQLITE_VERSION_NUMBER}}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
NDK_HOME="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"

if [[ -z "$NDK_HOME" ]]; then
  for candidate in \
    "$HOME/Library/Android/sdk/ndk/29.0.14206865" \
    "/Library/android/SDK/ndk/29.0.14206865" \
    "$HOME/Library/Android/sdk/ndk/27.1.12297006" \
    "/Library/android/SDK/ndk/27.1.12297006"; do
    if [[ -d "$candidate" ]]; then
      NDK_HOME="$candidate"
      break
    fi
  done
fi

if [[ -z "$NDK_HOME" || ! -d "$NDK_HOME" ]]; then
  echo "ANDROID_NDK_HOME or ANDROID_NDK_ROOT must point to an Android NDK." >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin) HOST_TAG="darwin-x86_64" ;;
  Linux) HOST_TAG="linux-x86_64" ;;
  *) echo "Unsupported host: $(uname -s)" >&2; exit 1 ;;
esac

TOOLCHAIN="$NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin"
if [[ ! -d "$TOOLCHAIN" ]]; then
  echo "Cannot find NDK LLVM toolchain: $TOOLCHAIN" >&2
  exit 1
fi

if [[ ! -f "$SOURCE_DIR/sqlite3.c" || ! -f "$SOURCE_DIR/shell.c" ]]; then
  echo "SQLite amalgamation not found. Run scripts/download_sqlite.sh first." >&2
  exit 1
fi

COMMON_CFLAGS=(
  -Os
  -fPIE
  -DSQLITE_THREADSAFE=1
  -DSQLITE_ENABLE_COLUMN_METADATA
  -DSQLITE_ENABLE_DBSTAT_VTAB
  -DSQLITE_ENABLE_EXPLAIN_COMMENTS
  -DSQLITE_ENABLE_FTS4
  -DSQLITE_ENABLE_FTS5
  -DSQLITE_ENABLE_MATH_FUNCTIONS
  -DSQLITE_ENABLE_RTREE
  -DSQLITE_ENABLE_UNLOCK_NOTIFY
  -DSQLITE_HAVE_ZLIB=1
  -DHAVE_READLINE=0
  -DSQLITE_ENABLE_DBPAGE_VTAB
)
COMMON_LDFLAGS=(-pie -ldl -lm -lz)

build_one() {
  local abi="$1"
  local compiler="$2"
  local out_dir="$DIST_DIR/$abi"
  mkdir -p "$out_dir"

  "$TOOLCHAIN/$compiler" \
    "${COMMON_CFLAGS[@]}" \
    "$SOURCE_DIR/shell.c" "$SOURCE_DIR/sqlite3.c" \
    -o "$out_dir/sqlite3" \
    "${COMMON_LDFLAGS[@]}"

  "$TOOLCHAIN/llvm-strip" "$out_dir/sqlite3"
  chmod 0755 "$out_dir/sqlite3"
}

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

build_one "arm64-v8a" "aarch64-linux-android${API_LEVEL}-clang"
build_one "armeabi-v7a" "armv7a-linux-androideabi${API_LEVEL}-clang"
build_one "x86_64" "x86_64-linux-android${API_LEVEL}-clang"

(
  cd "$DIST_DIR"
  zip -qr "sqlite3-android-${SQLITE_VERSION}.zip" arm64-v8a armeabi-v7a x86_64
)

find "$DIST_DIR" -maxdepth 2 -type f -print
