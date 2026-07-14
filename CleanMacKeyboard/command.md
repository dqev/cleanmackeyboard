# Build & DMG Generation

## Prerequisites
```bash
pip3 install --break-system-packages dmgbuild
```

## Build Release App
```bash
xcodebuild -project CleanMacKeyboard.xcodeproj -scheme CleanMacKeyboard -configuration Release clean build
```

## Generate Styled DMG
```bash
# Prepare source
rm -rf /tmp/cleanmac_dmg
mkdir -p /tmp/cleanmac_dmg
cp -R ~/Library/Developer/Xcode/DerivedData/CleanMacKeyboard-*/Build/Products/Release/CleanMacKeyboard.app /tmp/cleanmac_dmg/CleanMacKeyboard.app
ln -sf /Applications /tmp/cleanmac_dmg/Applications

# Create DMG with dmgbuild
dmgbuild -s /dev/stdin "CleanMacKeyboard" "CleanMacKeyboard.dmg" <<- PYEOF
volume_name = "CleanMacKeyboard"
format = "UDZO"
compression_level = 9
size = "8M"
files = ["/tmp/cleanmac_dmg/CleanMacKeyboard.app"]
symlinks = {"Applications": "/Applications"}
icon_size = 128
window_position = (100, 100)
window_size = (400, 300)
icon_locations = {
    "CleanMacKeyboard.app": (80, 130),
    "Applications": (300, 130),
}
text_size = 13
PYEOF

# Cleanup
rm -rf /tmp/cleanmac_dmg
```
