#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=$(grep 'version:' "$REPO_ROOT/app/pubspec.yaml" | head -n1 | cut -d' ' -f2 | cut -d'+' -f1)

echo "=== Building TodoCat Linux App (${VERSION}) ==="

# Check if running natively on Linux or using Docker on macOS
if [ "$(uname)" = "Darwin" ]; then
    echo "Running on macOS: Building inside Docker container..."
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is required to build Linux binaries on macOS."
        exit 1
    fi

    IMAGE_TAG="todocat-linux-builder:latest"
    echo "1. Preparing Docker build environment..."
    docker build -t "$IMAGE_TAG" -f "$REPO_ROOT/scripts/Dockerfile.linux" "$REPO_ROOT/scripts"

    echo "2. Compiling Linux release inside Docker..."
    docker run --rm \
        -v "$REPO_ROOT:/workspace" \
        -w /workspace \
        "$IMAGE_TAG" \
        bash -c "
            set -e
            cd app
            flutter pub get
            flutter build linux --release
        "
else
    echo "Running natively on Linux..."
    cd "$REPO_ROOT/app"
    flutter pub get
    flutter build linux --release
fi

echo "3. Packaging Standalone Linux Bundle..."
BUNDLE_DIR="$REPO_ROOT/app/build/linux/x64/release/bundle"
OUTPUT_TAR="$REPO_ROOT/TodoCat-${VERSION}-linux-x64.tar.gz"

if [ -d "$BUNDLE_DIR" ]; then
    # Copy desktop launcher and icon into bundle
    cp "$REPO_ROOT/app/linux/todocat.desktop" "$BUNDLE_DIR/"
    cp "$REPO_ROOT/app/linux/todocat.png" "$BUNDLE_DIR/"

    # Create run script
    cat << 'EOF' > "$BUNDLE_DIR/run.sh"
#!/bin/bash
DIR="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$DIR/lib:$LD_LIBRARY_PATH"
exec "$DIR/todocat" "$@"
EOF
    chmod +x "$BUNDLE_DIR/run.sh"

    tar -czvf "$OUTPUT_TAR" -C "$BUNDLE_DIR" .
    echo "Done! Linux portable bundle created at: $OUTPUT_TAR"
else
    echo "Warning: Bundle directory not found at $BUNDLE_DIR"
fi
