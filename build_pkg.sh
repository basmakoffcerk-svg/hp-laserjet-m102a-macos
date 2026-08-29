#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$DIR/build"
PAYLOAD_DIR="$BUILD_DIR/payload"
SCRIPTS_DIR="$BUILD_DIR/scripts"

rm -rf "$BUILD_DIR"
mkdir -p "$PAYLOAD_DIR/Library/Printers/PPDs/Contents/Resources"
mkdir -p "$SCRIPTS_DIR"

# Copy PPD
cp "$DIR/HP_LaserJet_Pro_M102a.ppd" "$PAYLOAD_DIR/Library/Printers/PPDs/Contents/Resources/HP_LaserJet_Pro_M102a.ppd"
chmod 644 "$PAYLOAD_DIR/Library/Printers/PPDs/Contents/Resources/HP_LaserJet_Pro_M102a.ppd"

# Create postinstall script
cat <<'POSTINSTALL_EOF' > "$SCRIPTS_DIR/postinstall"
#!/bin/bash

PPD_PATH="/Library/Printers/PPDs/Contents/Resources/HP_LaserJet_Pro_M102a.ppd"
PRINTER_NAME="HP_LaserJet_Pro_M102a"
DISPLAY_NAME="HP LaserJet Pro M102a (Custom Driver)"

# Find HP LaserJet USB Device URI
DEVICE_URI=$(lpinfo -v 2>/dev/null | grep -iE "HP.*LaserJet.*M10[1-6]|HP.*M102" | head -n 1 | awk '{print $2}')

if [ -z "$DEVICE_URI" ]; then
    # Fallback to standard USB or IPP-USB URI pattern
    DEVICE_URI="usb://HP/HP%20LaserJet%20M101-M106?serial=VNC3T83794"
fi

echo "Configuring CUPS queue $PRINTER_NAME with PPD $PPD_PATH and URI $DEVICE_URI..."

# Add / update printer queue
lpadmin -p "$PRINTER_NAME" -E -v "$DEVICE_URI" -P "$PPD_PATH" -D "$DISPLAY_NAME" -o printer-is-shared=false 2>/dev/null || true

# Set options
lpadmin -p "$PRINTER_NAME" -o PageSize=A4 -o Resolution=600dpi -o HPTonerSave=False 2>/dev/null || true

# Enable and accept jobs
cupsenable "$PRINTER_NAME" 2>/dev/null || true
cupsaccept "$PRINTER_NAME" 2>/dev/null || true

# Set as default printer if requested or if it's the main HP printer
lpadmin -d "$PRINTER_NAME" 2>/dev/null || true

echo "Installation complete."
exit 0
POSTINSTALL_EOF

chmod 755 "$SCRIPTS_DIR/postinstall"

echo "Building package HP_LaserJet_Pro_M102a_Driver.pkg..."
pkgbuild \
  --root "$PAYLOAD_DIR" \
  --scripts "$SCRIPTS_DIR" \
  --identifier "com.custom.hp.laserjet.m102a" \
  --version "1.0.0" \
  --install-location "/" \
  "$DIR/HP_LaserJet_Pro_M102a_Driver.pkg"

rm -rf "$BUILD_DIR"
echo "Build succeeded: $DIR/HP_LaserJet_Pro_M102a_Driver.pkg"
