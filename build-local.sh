#!/bin/bash

# ZMK Local Build Script
# Builds keyball39 firmware locally using Docker

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔨 Building ZMK firmware for Keyball39..."
echo ""

# Check if secrets.dtsi exists
if [ ! -f "config/secrets.dtsi" ]; then
    echo "❌ Error: config/secrets.dtsi not found!"
    echo "Please copy config/secrets.dtsi.example to config/secrets.dtsi and edit with your passwords."
    exit 1
fi

# Create build directory if it doesn't exist
mkdir -p build

# Build using Docker with the zmk-config approach
echo "🐳 Using Docker to build firmware..."
echo ""

docker run --rm -it \
    -v "$SCRIPT_DIR":/workspace \
    -w /workspace \
    zmkfirmware/zmk-build-arm:stable \
    /bin/bash -c "
        set -e
        cd /workspace
        
        # Remove .west to force reinit (reuses existing clones)
        rm -rf .west/
        
        # Initialize west workspace (will reuse existing modules)
        west init -l config/
        west update
        west zephyr-export
        
        # Build left half
        echo '📦 Building left half...'
        west build -s zmk/app -b nice_nano_v2 -d build/left -- -DSHIELD=keyball39_left -DZMK_CONFIG=/workspace/config
        cp build/left/zephyr/zmk.uf2 keyball39_left.uf2
        echo '✅ Left half complete: keyball39_left.uf2'
        
        # Clean for right half
        rm -rf build/right
        
        # Build right half  
        echo '📦 Building right half...'
        west build -s zmk/app -b nice_nano_v2 -d build/right -- -DSHIELD=keyball39_right -DZMK_CONFIG=/workspace/config
        cp build/right/zephyr/zmk.uf2 keyball39_right.uf2
        echo '✅ Right half complete: keyball39_right.uf2'
    "

echo ""
echo "🎉 Build complete!"
echo ""
echo "Firmware files:"
echo "  - keyball39_left.uf2"
echo "  - keyball39_right.uf2"
echo ""
echo "📝 To flash:"
echo "1. Double-tap reset button on left nice!nano"
echo "2. Copy: cp keyball39_left.uf2 /path/to/mounted/NICENANO/"
echo "3. Double-tap reset button on right nice!nano"
echo "4. Copy: cp keyball39_right.uf2 /path/to/mounted/NICENANO/"
