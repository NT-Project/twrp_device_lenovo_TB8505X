#!/usr/bin/env bash
#
# Apply final TWRP source changes for Lenovo Tab M8 TB-8505X.
#
# Target:
#   TeamWin / Omni TWRP Android 10 source
#
# Run from anywhere:
#   bash device/Lenovo/TB8505X/patches/apply.sh
#
set -euo pipefail

PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$(cd "$PATCH_DIR/../../../.." && pwd)"
RECOVERY_DIR="$SRC_ROOT/bootable/recovery"

CORE_PATCH="$PATCH_DIR/tb8505x-twrp-core.patch"
VDC_SRC="$PATCH_DIR/vdc_pie-arm64"
VDC_DST="$RECOVERY_DIR/prebuilt/vdc_pie-arm64"

VI_SRC="$PATCH_DIR/vi.xml"
VI_DST="$RECOVERY_DIR/gui/theme/common/languages/vi.xml"

echo "==> TB-8505X TWRP source setup"
echo "    Source root: $SRC_ROOT"

if [ ! -d "$RECOVERY_DIR/.git" ]; then
    echo "ERROR: bootable/recovery Git tree not found:" >&2
    echo "       $RECOVERY_DIR" >&2
    exit 1
fi

if [ ! -f "$CORE_PATCH" ]; then
    echo "ERROR: Missing core patch: $CORE_PATCH" >&2
    exit 1
fi

echo "==> Applying final TB-8505X TWRP core patch"

cd "$RECOVERY_DIR"

if git apply --check "$CORE_PATCH" 2>/dev/null; then
    git apply "$CORE_PATCH"
    echo "    Core patch applied."
elif git apply --reverse --check "$CORE_PATCH" 2>/dev/null; then
    echo "    Core patch already applied."
else
    echo "ERROR: Core patch cannot be applied cleanly." >&2
    echo "       Check bootable/recovery source revision and local changes." >&2
    exit 1
fi

echo "==> Installing patched Android 10 vdc_pie"

if [ ! -f "$VDC_SRC" ]; then
    echo "ERROR: Missing vdc_pie-arm64: $VDC_SRC" >&2
    exit 1
fi

cp -f "$VDC_SRC" "$VDC_DST"
chmod 0755 "$VDC_DST"

echo "==> Installing Vietnamese localization"

if [ ! -f "$VI_SRC" ]; then
    echo "ERROR: Missing vi.xml: $VI_SRC" >&2
    exit 1
fi

cp -f "$VI_SRC" "$VI_DST"

echo "==> Installing compatibility headers"

ZIP_SRC="$SRC_ROOT/system/core/libziparchive/include/ziparchive"
BASE_SRC="$SRC_ROOT/system/core/base/include/android-base"

ZIP_DST="$SRC_ROOT/system/core/include/ziparchive"
BASE_DST="$SRC_ROOT/system/core/include/android-base"

if [ ! -d "$ZIP_SRC" ]; then
    echo "ERROR: Missing $ZIP_SRC" >&2
    exit 1
fi

if [ ! -d "$BASE_SRC" ]; then
    echo "ERROR: Missing $BASE_SRC" >&2
    exit 1
fi

mkdir -p "$ZIP_DST" "$BASE_DST"

cp -f "$ZIP_SRC"/*.h "$ZIP_DST/"
cp -f "$BASE_SRC"/*.h "$BASE_DST/"

echo
echo "TB-8505X source patches applied successfully."
