#!/bin/bash
#
# Ensures docs/examples/js/elm-motion.js is up-to-date with the master
# sources in js/src/. Rebuilds the rollup bundle (dist/elm-motion.js)
# whenever any js/src/**/*.js file is newer than dist/elm-motion.js,
# and copies the bundle into docs/examples/js/ whenever the dist file
# is newer than the copy.
#
# Sourced or invoked by build-docs-examples.sh and build-example.sh so
# the WAAPI examples always load the latest companion JS after any edit
# under js/src/.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$REPO_ROOT/js/src"
DIST_FILE="$REPO_ROOT/dist/elm-motion.js"
EXAMPLES_FILE="$REPO_ROOT/docs/examples/js/elm-motion.js"

mkdir -p "$(dirname "$EXAMPLES_FILE")"

# Portable mtime in epoch seconds: GNU stat (Linux) uses -c %Y, BSD stat
# (macOS) uses -f %m. Detect once at startup so the rest of the script
# stays platform-agnostic.
if stat -c %Y "$0" >/dev/null 2>&1; then
    _stat_mtime() { stat -c %Y "$1"; }
else
    _stat_mtime() { stat -f %m "$1"; }
fi

# Find the newest mtime under js/src/ (epoch seconds).
newest_src_mtime() {
    local newest=0 mtime
    while IFS= read -r -d '' file; do
        mtime=$(_stat_mtime "$file" 2>/dev/null || echo 0)
        if [ "$mtime" -gt "$newest" ]; then
            newest=$mtime
        fi
    done < <(find "$SRC_DIR" -type f -name '*.js' -print0)
    echo "$newest"
}

file_mtime() {
    [ -f "$1" ] && _stat_mtime "$1" 2>/dev/null || echo 0
}

SRC_MTIME=$(newest_src_mtime)
DIST_MTIME=$(file_mtime "$DIST_FILE")
EXAMPLES_MTIME=$(file_mtime "$EXAMPLES_FILE")

NEED_BUILD=0
if [ ! -f "$DIST_FILE" ] || [ "${SRC_MTIME:-0}" -gt "$DIST_MTIME" ]; then
    NEED_BUILD=1
fi

if [ "$NEED_BUILD" -eq 1 ]; then
    echo "📦 js/src/ is newer than dist/elm-motion.js - running 'npm run build'..."
    (cd "$REPO_ROOT" && npm run build) || {
        echo "❌ npm run build failed - cannot refresh dist/elm-motion.js"
        exit 1
    }
    DIST_MTIME=$(file_mtime "$DIST_FILE")
fi

if [ ! -f "$EXAMPLES_FILE" ] || [ "$DIST_MTIME" -gt "$EXAMPLES_MTIME" ]; then
    cp "$DIST_FILE" "$EXAMPLES_FILE"
    echo "✅ Copied dist/elm-motion.js → docs/examples/js/elm-motion.js"
else
    echo "✅ docs/examples/js/elm-motion.js is up-to-date"
fi
