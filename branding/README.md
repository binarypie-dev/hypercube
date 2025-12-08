# Hypercube Branding Assets

This directory contains the branding assets for the Hypercube Linux distribution.

## Current Assets

### Logo
- `hypercube-logo.png` - 200x200 neon hypercube logo (auto-generated)

### Plymouth Boot Theme
Located in `plymouth/hypercube/`:
- `hypercube.plymouth` - Theme configuration file
- `hypercube.script` - Plymouth script for boot animation
- `background.png` - Full boot splash background (from `dot_files/hypr/background.webp`)
- `logo.png` - Centered logo displayed during boot
- `spinner-*.png` - 12-frame rotating spinner animation (pink/blue/purple neon dots)
- `progress-bg.png` - Progress bar background
- `progress-fg.png` - Progress bar fill (neon gradient)

## Regenerating Assets

If you want to modify or regenerate the Plymouth theme assets:

```bash
cd branding/plymouth
./generate-assets.sh
```

This requires one of: `rsvg-convert`, `inkscape`, or `imagemagick`.

## Customization

### To Replace the Logo
1. Create your custom logo (recommended: 200x200 PNG with transparent background)
2. Replace `hypercube-logo.png` in this directory
3. Replace `plymouth/hypercube/logo.png` for the boot splash

### To Replace the Boot Background
1. Create your background image (recommended: 1920x1080 or higher)
2. Replace `plymouth/hypercube/background.png`
3. Or modify `dot_files/hypr/background.webp` and regenerate

### To Customize the Spinner
Edit `plymouth/generate-assets.sh` and modify:
- `PINK`, `BLUE`, `PURPLE` color variables
- The SVG structure in the spinner generation loop

## Color Scheme

The current theme uses these neon colors (matching the background):
- Pink: `#FF1493`
- Blue: `#00BFFF`
- Purple: `#8A2BE2`
- Background: `#0a0a0f`

## Files Installed During Build

The build process installs:
- `/usr/share/pixmaps/hypercube-logo.png`
- `/usr/share/plymouth/themes/hypercube/*`
- `/etc/plymouth/plymouthd.conf` (sets Hypercube as default theme)

## OS Branding

In addition to visual assets, `build_files/00-hypercube-branding.sh` modifies:
- `/usr/lib/os-release` - Sets NAME="Hypercube", ID=hypercube
- `/usr/share/hypercube/image-info.json` - Build metadata
