#!/bin/bash

# Get Device UDID - Multiple Methods
# This script helps you find your iPhone/iPad UDID for development

echo "🔍 Finding Device UDID..."
echo ""

# Method 1: Using instruments (most reliable for physical devices)
echo "📱 Method 1: Physical Devices (USB Connected)"
echo "-----------------------------------"
# Try to find instruments using xcrun
INSTRUMENTS_CMD=""
if command -v xcrun &> /dev/null; then
    INSTRUMENTS_CMD=$(xcrun --find instruments 2>/dev/null)
fi

if [ -n "$INSTRUMENTS_CMD" ] && [ -f "$INSTRUMENTS_CMD" ]; then
    PHYSICAL_DEVICES=$("$INSTRUMENTS_CMD" -s devices 2>/dev/null | grep -E "iPhone|iPad" | grep -v "Simulator" | grep -v "^Known Devices:" | head -5)
    if [ -n "$PHYSICAL_DEVICES" ]; then
        echo "✅ Found physical device(s):"
        echo ""
        echo "$PHYSICAL_DEVICES" | while IFS= read -r line; do
            if [ -n "$line" ]; then
                # Extract UDID (format: Device Name (UDID))
                UDID=$(echo "$line" | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' | head -1)
                DEVICE_NAME=$(echo "$line" | sed -E 's/ \(.*$//' | xargs)
                if [ -n "$UDID" ]; then
                    echo "   📱 $DEVICE_NAME"
                    echo "   🆔 $UDID"
                    echo ""
                else
                    # Try alternative UDID format (40 hex chars, no dashes)
                    ALT_UDID=$(echo "$line" | grep -oE '[A-F0-9]{40}' | head -1)
                    if [ -n "$ALT_UDID" ]; then
                        echo "   📱 $DEVICE_NAME"
                        echo "   🆔 $ALT_UDID"
                        echo ""
                    fi
                fi
            fi
        done
    else
        echo "ℹ️  No physical devices found"
        echo "   → Connect your iPhone/iPad via USB"
        echo "   → Trust this computer when prompted on device"
        echo "   → Unlock your device"
    fi
else
    echo "ℹ️  Xcode command line tools not available"
    echo "   → Install Xcode from the App Store"
    echo "   → Or run: xcode-select --install"
fi
echo ""

# Method 2: Using xcrun simctl (for simulators)
echo "📱 Method 2: iOS Simulators"
echo "-----------------------------------"
xcrun simctl list devices available 2>/dev/null | grep -E "iPhone|iPad" | head -5 || echo "ℹ️  No simulators found"
echo ""

# Method 3: Using Xcode's devices command
echo "📱 Method 3: Xcode Devices"
echo "-----------------------------------"
if command -v xcrun &> /dev/null; then
    xcrun xctrace list devices 2>/dev/null | grep -E "iPhone|iPad" || echo "ℹ️  Run this from Xcode: Window > Devices and Simulators"
else
    echo "ℹ️  Xcode command line tools not found"
fi
echo ""

# Method 4: Instructions for manual methods
echo "📱 Method 4: On Your iPhone/iPad"
echo "-----------------------------------"
echo "1. Open Settings app"
echo "2. Go to General > About"
echo "3. Scroll down and tap 'Copy Identifier' (or look for 'Identifier')"
echo "4. The UDID is a long string like: 00008030-001A4D1234567890"
echo ""

echo "📱 Method 5: Using Finder (macOS Catalina+)"
echo "-----------------------------------"
echo "1. Connect your iPhone/iPad to Mac via USB"
echo "2. Open Finder"
echo "3. Click on your device name in the sidebar"
echo "4. Click on the serial number (it will change to show UDID)"
echo "5. Right-click and Copy, or Cmd+C"
echo ""

echo "📱 Method 6: Using Xcode GUI"
echo "-----------------------------------"
echo "1. Connect your device to Mac"
echo "2. Open Xcode"
echo "3. Go to Window > Devices and Simulators (Shift+Cmd+2)"
echo "4. Select your device in the left sidebar"
echo "5. The UDID is shown in the device info panel"
echo "6. Right-click on it to copy"
echo ""

# Try to get UDID from connected device using idevice_id (if libimobiledevice is installed)
if command -v idevice_id &> /dev/null; then
    echo "📱 Method 7: Using libimobiledevice"
    echo "-----------------------------------"
    UDIDS=$(idevice_id -l 2>/dev/null)
    if [ -n "$UDIDS" ]; then
        echo "✅ Found connected device(s):"
        echo "$UDIDS"
    else
        echo "ℹ️  No devices found (install libimobiledevice: brew install libimobiledevice)"
    fi
    echo ""
fi


echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Quick Tip:"
echo "   The easiest method is usually:"
echo "   Settings > General > About > Copy Identifier"
echo ""
echo "   Or connect via USB and use:"
echo "   Xcode > Window > Devices and Simulators"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

