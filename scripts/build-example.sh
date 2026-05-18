#!/bin/bash

# Elm Motion Example Build Script
# Compiles one or many Elm example files to their JavaScript outputs.
#
# Accepts plain paths or glob patterns (relative to docs/examples/src/).
# Globs containing wildcards should be quoted so the shell doesn't
# expand them against the wrong directory.
#
# Usage: ./scripts/build-example.sh Animation/Transition/HelloText
#        ./scripts/build-example.sh Animation/Transition/HelloText/Main.elm
#        ./scripts/build-example.sh 'Animation/Transition/InterruptingAnimations/*'
#        ./scripts/build-example.sh 'Animation/*/HelloText'
#        ./scripts/build-example.sh --debug Animation/WAAPI/Perspective3D


set -e  # Exit on any error

# Parse args: --debug may appear anywhere; everything else is an input path/glob.
DEBUG_MODE=0
POSITIONAL=()
for arg in "$@"; do
    case "$arg" in
        --debug)
            DEBUG_MODE=1
            ;;
        *)
            POSITIONAL+=("$arg")
            ;;
    esac
done
set -- "${POSITIONAL[@]}"

# Check if path argument is provided
if [ $# -eq 0 ]; then
    echo "❌ Error: No file path provided"
    echo ""
    echo "Usage: $0 [--debug] <path-or-glob> [<path-or-glob> ...]"
    echo ""
    echo "Examples:"
    echo "  $0 Animation/Transition/HelloText"
    echo "  $0 Animation/Transition/HelloText/Main.elm"
    echo "  $0 'Animation/Transition/InterruptingAnimations/*'"
    echo "  $0 'Animation/*/HelloText'"
    echo "  $0 --debug Animation/WAAPI/Perspective3D"
    echo ""
    echo "Flags:"
    echo "  --debug   Compile without --optimize so Debug.log and the Elm"
    echo "            time-travelling debugger remain available."
    echo ""
    echo "Paths are relative to docs/examples/src/. Patterns with wildcards"
    echo "should be quoted so the shell does not expand them against the"
    echo "current directory."
    exit 1
fi

# Use Elm tools provisioned by elm-tooling (see elm-tooling.json)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$REPO_ROOT/node_modules/.bin:$PATH"

# Ensure docs/examples/js/elm-motion.js reflects any edits under js/src/
# before compiling, so the example loads the latest companion JS.
bash "$REPO_ROOT/scripts/ensure-examples-js.sh"

# Change to docs/examples directory from project root
cd "$(dirname "$0")/../docs/examples"

# Track formatting results
FORMATTED_FILES=()
FAILED_FORMAT=()

# Format all files before building
echo "🎨 Formatting all files..."

while IFS= read -r -d '' file; do
    if elm-format --yes "$file" > /dev/null 2>&1; then
        FORMATTED_FILES+=("$file")
    else
        FAILED_FORMAT+=("$file")
    fi
done < <(find src -name "*.elm" -type f -print0 2>/dev/null)

echo ""

# Resolve every positional argument into a concrete list of Main.elm files.
SOURCES=()
shopt -s nullglob
for input in "${POSITIONAL[@]}"; do
    # Normalize: strip leading src/, leading/trailing slashes.
    norm="$input"
    norm="${norm#src/}"
    norm="${norm#/}"
    norm="${norm%/}"

    matched=()

    if [[ "$norm" == *.elm ]]; then
        # Explicit .elm path or glob ending in .elm
        for m in src/$norm; do
            [ -f "$m" ] && matched+=("$m")
        done
    else
        # Treat as directory or glob of directories; pick Main.elm in each.
        for m in src/$norm; do
            if [ -d "$m" ] && [ -f "$m/Main.elm" ]; then
                matched+=("$m/Main.elm")
            elif [ -f "$m/Main.elm" ]; then
                matched+=("$m/Main.elm")
            fi
        done
        # Fallback: literal directory that the glob didn't expand to.
        if [ ${#matched[@]} -eq 0 ] && [ -f "src/$norm/Main.elm" ]; then
            matched+=("src/$norm/Main.elm")
        fi
    fi

    if [ ${#matched[@]} -eq 0 ]; then
        echo "❌ Error: No examples matched: $input"
        echo "   Looked under: $(pwd)/src/$norm"
        exit 1
    fi

    SOURCES+=("${matched[@]}")
done
shopt -u nullglob

# Deduplicate while preserving order (portable: no associative arrays).
UNIQUE_SOURCES=()
for s in "${SOURCES[@]}"; do
    skip=0
    for u in "${UNIQUE_SOURCES[@]}"; do
        if [ "$u" = "$s" ]; then
            skip=1
            break
        fi
    done
    [ "$skip" -eq 0 ] && UNIQUE_SOURCES+=("$s")
done
SOURCES=("${UNIQUE_SOURCES[@]}")

# Assemble elm make flags. Default is --optimize; --debug opts out.
ELM_MAKE_FLAGS=()
if [ "$DEBUG_MODE" -eq 1 ]; then
    echo "🐛 Debug mode: building without --optimize"
    echo ""
else
    ELM_MAKE_FLAGS+=(--optimize)
fi

echo "🚀 Building ${#SOURCES[@]} example(s) from $(pwd)..."
echo ""

SUCCESS_COUNT=0
FAILED_BUILDS=()

for src_file in "${SOURCES[@]}"; do
    # Generate output: replace /Main.elm with /index.js, otherwise swap .elm -> .js
    output_file=$(echo "$src_file" | sed 's|/Main\.elm$|/index.js|' | sed 's|\.elm$|.js|')
    mkdir -p "$(dirname "$output_file")"

    echo "🔨 $src_file → $output_file"
    if elm make "$src_file" "${ELM_MAKE_FLAGS[@]}" --output="$output_file" > /dev/null 2>&1; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo "   ✅ ok"
    else
        FAILED_BUILDS+=("$src_file")
        echo "   ❌ failed"
        # Re-run to surface the error to the user.
        elm make "$src_file" "${ELM_MAKE_FLAGS[@]}" --output="$output_file" || true
    fi
done

echo ""
echo "📊 Build Summary:"
echo "✅ Successful builds: $SUCCESS_COUNT"
echo "❌ Failed builds: ${#FAILED_BUILDS[@]}"
if [ ${#FAILED_BUILDS[@]} -gt 0 ]; then
    for f in "${FAILED_BUILDS[@]}"; do
        echo "   - $f"
    done
fi
echo ""
echo "📊 Format Summary:"
echo "✅ Successfully formatted: ${#FORMATTED_FILES[@]} files"
if [ ${#FAILED_FORMAT[@]} -gt 0 ]; then
    echo "⚠️  Failed to format: ${#FAILED_FORMAT[@]} files"
    for failed_file in "${FAILED_FORMAT[@]}"; do
        display_path="${failed_file#src/}"
        echo "   - $display_path"
    done
else
    echo "❌ Failed to format: 0 files"
fi

if [ ${#FAILED_BUILDS[@]} -gt 0 ]; then
    exit 1
fi

