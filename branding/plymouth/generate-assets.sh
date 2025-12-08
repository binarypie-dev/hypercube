#!/bin/bash
# Generate Plymouth theme assets for Hypercube
# This script creates the spinner frames and progress bar images
# Requires: ImageMagick (convert), inkscape or rsvg-convert for SVG

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$SCRIPT_DIR/hypercube"

echo "Generating Hypercube Plymouth theme assets..."

# Colors matching the neon hypercube theme
PINK="#FF1493"
BLUE="#00BFFF"
PURPLE="#8A2BE2"
BG_COLOR="#0a0a0f"

# Create spinner frames (12 frames for smooth rotation)
echo "Creating spinner frames..."
for i in $(seq 0 11); do
    angle=$((i * 30))

    # Create an SVG spinner frame with rotating dots
    cat > "$THEME_DIR/spinner-$i.svg" << EOF
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <g transform="rotate($angle 32 32)">
    <!-- 8 dots in a circle, with varying opacity -->
    <circle cx="32" cy="8" r="4" fill="$PINK" opacity="1.0"/>
    <circle cx="49" cy="15" r="4" fill="$PINK" opacity="0.875"/>
    <circle cx="56" cy="32" r="4" fill="$BLUE" opacity="0.75"/>
    <circle cx="49" cy="49" r="4" fill="$BLUE" opacity="0.625"/>
    <circle cx="32" cy="56" r="4" fill="$PURPLE" opacity="0.5"/>
    <circle cx="15" cy="49" r="4" fill="$PURPLE" opacity="0.375"/>
    <circle cx="8" cy="32" r="4" fill="$PINK" opacity="0.25"/>
    <circle cx="15" cy="15" r="4" fill="$PINK" opacity="0.125"/>
  </g>
</svg>
EOF

    # Convert SVG to PNG (try multiple converters)
    if command -v rsvg-convert &> /dev/null; then
        rsvg-convert -w 64 -h 64 "$THEME_DIR/spinner-$i.svg" -o "$THEME_DIR/spinner-$i.png"
    elif command -v inkscape &> /dev/null; then
        inkscape -w 64 -h 64 "$THEME_DIR/spinner-$i.svg" -o "$THEME_DIR/spinner-$i.png" 2>/dev/null
    elif command -v convert &> /dev/null; then
        convert -background none "$THEME_DIR/spinner-$i.svg" "$THEME_DIR/spinner-$i.png"
    else
        echo "Warning: No SVG converter found. Please install rsvg-convert, inkscape, or imagemagick"
        echo "Keeping SVG files for manual conversion"
    fi
done

# Create progress bar background
echo "Creating progress bar..."
cat > "$THEME_DIR/progress-bg.svg" << EOF
<svg xmlns="http://www.w3.org/2000/svg" width="400" height="8" viewBox="0 0 400 8">
  <rect x="0" y="0" width="400" height="8" rx="4" fill="#1a1a2e" stroke="$PURPLE" stroke-width="1"/>
</svg>
EOF

# Create progress bar foreground (gradient from pink to blue)
cat > "$THEME_DIR/progress-fg.svg" << EOF
<svg xmlns="http://www.w3.org/2000/svg" width="396" height="4" viewBox="0 0 396 4">
  <defs>
    <linearGradient id="neonGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:$PINK;stop-opacity:1" />
      <stop offset="50%" style="stop-color:$PURPLE;stop-opacity:1" />
      <stop offset="100%" style="stop-color:$BLUE;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect x="0" y="0" width="396" height="4" rx="2" fill="url(#neonGrad)"/>
</svg>
EOF

# Convert progress bar SVGs to PNG
if command -v rsvg-convert &> /dev/null; then
    rsvg-convert -w 400 -h 8 "$THEME_DIR/progress-bg.svg" -o "$THEME_DIR/progress-bg.png"
    rsvg-convert -w 396 -h 4 "$THEME_DIR/progress-fg.svg" -o "$THEME_DIR/progress-fg.png"
elif command -v inkscape &> /dev/null; then
    inkscape -w 400 -h 8 "$THEME_DIR/progress-bg.svg" -o "$THEME_DIR/progress-bg.png" 2>/dev/null
    inkscape -w 396 -h 4 "$THEME_DIR/progress-fg.svg" -o "$THEME_DIR/progress-fg.png" 2>/dev/null
elif command -v convert &> /dev/null; then
    convert -background none "$THEME_DIR/progress-bg.svg" "$THEME_DIR/progress-bg.png"
    convert -background none "$THEME_DIR/progress-fg.svg" "$THEME_DIR/progress-fg.png"
fi

# Convert background.webp to PNG if it exists and we have the tools
BACKGROUND_SRC="$SCRIPT_DIR/../../dot_files/hypr/background.webp"
if [ -f "$BACKGROUND_SRC" ]; then
    echo "Converting background image..."
    if command -v convert &> /dev/null; then
        convert "$BACKGROUND_SRC" "$THEME_DIR/background.png"
    elif command -v ffmpeg &> /dev/null; then
        ffmpeg -y -i "$BACKGROUND_SRC" "$THEME_DIR/background.png" 2>/dev/null
    else
        echo "Warning: Cannot convert background.webp - please install imagemagick or ffmpeg"
        echo "Or manually convert dot_files/hypr/background.webp to branding/plymouth/hypercube/background.png"
    fi
fi

# Create a simple logo placeholder if it doesn't exist
if [ ! -f "$THEME_DIR/logo.png" ]; then
    echo "Creating placeholder logo..."
    cat > "$THEME_DIR/logo.svg" << EOF
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
  <defs>
    <linearGradient id="cubeGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:$PINK;stop-opacity:1" />
      <stop offset="100%" style="stop-color:$BLUE;stop-opacity:1" />
    </linearGradient>
    <filter id="glow">
      <feGaussianBlur stdDeviation="3" result="coloredBlur"/>
      <feMerge>
        <feMergeNode in="coloredBlur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <!-- Outer cube (rotated 45 degrees) -->
  <g transform="translate(100,100) rotate(45)" filter="url(#glow)">
    <rect x="-60" y="-60" width="120" height="120" fill="none" stroke="url(#cubeGrad)" stroke-width="4"/>
  </g>
  <!-- Text -->
  <text x="100" y="185" text-anchor="middle" font-family="sans-serif" font-size="16" fill="white" opacity="0.9">HYPERCUBE</text>
</svg>
EOF

    if command -v rsvg-convert &> /dev/null; then
        rsvg-convert -w 200 -h 200 "$THEME_DIR/logo.svg" -o "$THEME_DIR/logo.png"
    elif command -v inkscape &> /dev/null; then
        inkscape -w 200 -h 200 "$THEME_DIR/logo.svg" -o "$THEME_DIR/logo.png" 2>/dev/null
    elif command -v convert &> /dev/null; then
        convert -background none "$THEME_DIR/logo.svg" "$THEME_DIR/logo.png"
    fi
fi

# Clean up SVG files (optional - uncomment if you want to remove them)
# rm -f "$THEME_DIR"/*.svg

echo "Asset generation complete!"
echo ""
echo "Generated files in $THEME_DIR:"
ls -la "$THEME_DIR"/*.png 2>/dev/null || echo "  (PNG files will be generated when you run this script with proper tools installed)"
echo ""
echo "Required tools (in order of preference):"
echo "  - rsvg-convert (from librsvg2-tools)"
echo "  - inkscape"
echo "  - convert (from imagemagick)"
echo ""
echo "To install on Fedora: dnf install librsvg2-tools ImageMagick"
