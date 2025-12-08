#!/bin/bash
# Generate Plymouth watermark for Hypercube
# The watermark is displayed by Fedora's built-in spinner theme
# Requires: ImageMagick (convert), inkscape or rsvg-convert for SVG

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$SCRIPT_DIR/hypercube"

echo "Generating Hypercube Plymouth watermark..."

# Colors matching the neon hypercube theme
PINK="#FF1493"
BLUE="#00BFFF"

# Create watermark if it doesn't exist
if [ ! -f "$THEME_DIR/watermark.png" ]; then
    echo "Creating watermark..."
    cat > "$THEME_DIR/watermark.svg" << EOF
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
        rsvg-convert -w 200 -h 200 "$THEME_DIR/watermark.svg" -o "$THEME_DIR/watermark.png"
    elif command -v inkscape &> /dev/null; then
        inkscape -w 200 -h 200 "$THEME_DIR/watermark.svg" -o "$THEME_DIR/watermark.png" 2>/dev/null
    elif command -v convert &> /dev/null; then
        convert -background none "$THEME_DIR/watermark.svg" "$THEME_DIR/watermark.png"
    else
        echo "Warning: No SVG converter found. Please install rsvg-convert, inkscape, or imagemagick"
        exit 1
    fi

    # Clean up SVG
    rm -f "$THEME_DIR/watermark.svg"
fi

echo "Asset generation complete!"
echo ""
echo "Generated files in $THEME_DIR:"
ls -la "$THEME_DIR"/*.png 2>/dev/null || echo "  (No PNG files found)"
echo ""
echo "Required tools (in order of preference):"
echo "  - rsvg-convert (from librsvg2-tools)"
echo "  - inkscape"
echo "  - convert (from imagemagick)"
echo ""
echo "To install on Fedora: dnf install librsvg2-tools ImageMagick"
